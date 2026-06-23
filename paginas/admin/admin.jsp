<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
/* =========================================
   PROTEÇÃO DE ACESSO — APENAS ADMIN
========================================= */
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"ADMINISTRADOR".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());

/* =========================================
   DADOS DO ADMINISTRADOR
========================================= */
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String nomeAdmin = "";
String emailAdmin = "";

int totalUtilizadores = 0;
int totalAlunos = 0;
int totalCoordenadores = 0;
int totalDisciplinas = 0;
int totalTurmas = 0;
int totalInscricoes = 0;

try {
    con = dbConnect();

    /* Dados do administrador */
    ps = con.prepareStatement(
        "SELECT nome, email " +
        "FROM utilizadores " +
        "WHERE id = ? AND perfil = 'ADMINISTRADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        nomeAdmin = rs.getString("nome");
        emailAdmin = rs.getString("email");
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=admin_nao_encontrado");
        return;
    }

    dbClose(rs, ps, null);

    /* Total de utilizadores */
    ps = con.prepareStatement("SELECT COUNT(*) AS total FROM utilizadores");
    rs = dbQuery(con, ps);
    if (rs.next()) {
        totalUtilizadores = rs.getInt("total");
    }

    dbClose(rs, ps, null);

    /* Total de alunos */
    ps = con.prepareStatement("SELECT COUNT(*) AS total FROM alunos");
    rs = dbQuery(con, ps);
    if (rs.next()) {
        totalAlunos = rs.getInt("total");
    }

    dbClose(rs, ps, null);

    /* Total de coordenadores */
    ps = con.prepareStatement("SELECT COUNT(*) AS total FROM coordenadores");
    rs = dbQuery(con, ps);
    if (rs.next()) {
        totalCoordenadores = rs.getInt("total");
    }

    dbClose(rs, ps, null);

    /* Total de disciplinas */
    ps = con.prepareStatement("SELECT COUNT(*) AS total FROM disciplinas");
    rs = dbQuery(con, ps);
    if (rs.next()) {
        totalDisciplinas = rs.getInt("total");
    }

    dbClose(rs, ps, null);

    /* Total de turmas */
    ps = con.prepareStatement("SELECT COUNT(*) AS total FROM turmas");
    rs = dbQuery(con, ps);
    if (rs.next()) {
        totalTurmas = rs.getInt("total");
    }

    dbClose(rs, ps, null);

    /* Total de inscrições */
    ps = con.prepareStatement("SELECT COUNT(*) AS total FROM inscricoes");
    rs = dbQuery(con, ps);
    if (rs.next()) {
        totalInscricoes = rs.getInt("total");
    }

} catch (Exception e) {
    out.print("Erro ao carregar dados do administrador: " + e.getMessage());
} finally {
    dbClose(rs, ps, con);
}

String letraAvatar = "A";

if (nomeAdmin != null && nomeAdmin.trim().length() > 0) {
    letraAvatar = nomeAdmin.substring(0, 1).toUpperCase();
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">

    <meta 
        name="viewport" 
        content="width=device-width, initial-scale=1.0"
    >

    <title>Dashboard Administrador - Gesturma</title>

    <link rel="stylesheet" href="../../css/geral.css">
</head>

<body>

<div class="dashboard-container">

    <!-- MENU LATERAL -->
    <aside class="sidebar">

        <div class="brand">
            <div class="brand-icon">G</div>
            <span>Gesturma</span>
        </div>
        <nav class="menu">

            <a href="admin.jsp" class="active"> Dashboard</a>
            <a href="<%= request.getContextPath() %>/paginas/admin/utilizadores.jsp">Gestão Utilizadores</a>
            <a href="<%= request.getContextPath() %>/paginas/admin/disciplinas.jsp">Gestão de Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="inscricoes.jsp">Gestão de Inscrições</a>
            <a href="perfil.jsp">Meu Perfil</a>


        </nav>

        <div class="logout-area">
            <a 
                href="<%= request.getContextPath() %>/paginas/logout.jsp" 
                class="logout-btn"
            >
                Terminar sessão
            </a>
        </div>

    </aside>

    <!-- CONTEÚDO PRINCIPAL -->
    <main class="main-content">

        <!-- TOPO -->
        <header class="topbar">

            <div class="search-box">
                <input type="text" placeholder="Pesquisar no sistema...">
            </div>

            <div class="topbar-right">

                <div class="notification"></div>

                <div class="user-box">
                    <div class="user-avatar">
                        <%= letraAvatar %>
                    </div>

                    <div class="user-info">
                        <strong><%= nomeAdmin %></strong>
                        <span>Administrador</span>
                    </div>
                </div>

            </div>

        </header>

        <!-- TÍTULO -->
        <section class="page-header">
            <h1>Dashboard do Administrador</h1>
            <p>
                Bem-vindo ao painel administrativo do Gesturma. 
                Aqui podes acompanhar a informação geral do sistema.
            </p>
        </section>

        <!-- CARTÕES PRINCIPAIS -->
        <section class="cards-grid">

            <div class="info-card blue">
                <h3>Utilizadores</h3>
                <p><%= totalUtilizadores %></p>
            </div>

            <div class="info-card green">
                <h3>Alunos</h3>
                <p><%= totalAlunos %></p>
            </div>

            <div class="info-card orange">
                <h3>Coordenadores</h3>
                <p><%= totalCoordenadores %></p>
            </div>

            <div class="info-card pink">
                <h3>Disciplinas</h3>
                <p><%= totalDisciplinas %></p>
            </div>

        </section>

        <!-- SEGUNDA LINHA DE CARTÕES -->
        <section class="cards-grid">

            <div class="info-card blue">
                <h3>Turmas</h3>
                <p><%= totalTurmas %></p>
            </div>

            <div class="info-card green">
                <h3>Inscrições</h3>
                <p><%= totalInscricoes %></p>
            </div>

            <div class="info-card orange">
                <h3>Perfil</h3>
                <p>Admin</p>
            </div>

            <div class="info-card pink">
                <h3>Estado</h3>
                <p>Ativo</p>
            </div>

        </section>

        <!-- ÁREA DE CONTROLO -->
        <section class="profile-section">

            <div class="profile-card">

                <h2>Área de Administração</h2>

                <div class="profile-grid">

                    <div class="profile-item">
                        <span>Gestão de utilizadores</span>
                        <strong>Consultar e controlar contas</strong>
                    </div>

                    <div class="profile-item">
                        <span>Gestão académica</span>
                        <strong>Alunos, coordenadores e disciplinas</strong>
                    </div>

                    <div class="profile-item">
                        <span>Gestão de turmas</span>
                        <strong>Turmas, vagas e capacidades</strong>
                    </div>

                    <div class="profile-item">
                        <span>Gestão de inscrições</span>
                        <strong>Consultar inscrições dos alunos</strong>
                    </div>

                    <div class="profile-item">
                        <span>Horários</span>
                        <strong>Consulta dos horários das turmas</strong>
                    </div>

                    <div class="profile-item">
                        <span>Períodos de inscrição</span>
                        <strong>Controlo das datas de inscrição</strong>
                    </div>

                </div>

            </div>

        </section>

    </main>

</div>

</body>
</html>