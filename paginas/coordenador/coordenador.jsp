<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
/* =========================================
   PROTEÇÃO DE ACESSO — APENAS COORDENADOR
========================================= */
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"COORDENADOR".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());

/* =========================================
   DADOS DO COORDENADOR
========================================= */
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

int coordenadorId = 0;
String nomeCoordenador = "";
String emailCoordenador = "";
String cursoCoordenador = "";

int totalDisciplinas = 0;
int totalTurmas = 0;
int totalInscricoes = 0;
int totalPeriodos = 0;

try {
    con = dbConnect();

    /* Dados principais do coordenador */
    ps = con.prepareStatement(
        "SELECT " +
        "c.id AS coordenador_id, " +
        "u.nome, u.email, c.curso " +
        "FROM coordenadores c " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE u.id = ? " +
        "AND u.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        coordenadorId = rs.getInt("coordenador_id");
        nomeCoordenador = rs.getString("nome");
        emailCoordenador = rs.getString("email");
        cursoCoordenador = rs.getString("curso");
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=coordenador_nao_encontrado");
        return;
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    /* Total de disciplinas do coordenador */
    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM disciplinas " +
        "WHERE coordenador_id = ?"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        totalDisciplinas = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    /* Total de turmas das disciplinas do coordenador */
    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "WHERE d.coordenador_id = ?"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        totalTurmas = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    /* Total de inscrições nas disciplinas do coordenador */
    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM inscricoes i " +
        "INNER JOIN disciplinas d ON d.id = i.disciplina_id " +
        "WHERE d.coordenador_id = ?"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        totalInscricoes = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    /* Total de períodos de inscrição das disciplinas do coordenador */
    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM periodos_inscricao pi " +
        "INNER JOIN disciplinas d ON d.id = pi.disciplina_id " +
        "WHERE d.coordenador_id = ?"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        totalPeriodos = rs.getInt("total");
    }

} catch (Exception e) {
    out.print("Erro ao carregar dados do coordenador: " + e.getMessage());

} finally {
    dbClose(rs, ps, con);
}

String letraAvatar = "C";

if (nomeCoordenador != null && nomeCoordenador.trim().length() > 0) {
    letraAvatar = nomeCoordenador.substring(0, 1).toUpperCase();
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Dashboard Coordenador - Gesturma</title>
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

            <a href="coordenador.jsp" class="active">Dashboard</a>
            <a href="disciplinas.jsp">Minhas Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="gestao_inscricoes.jsp">Gestão de Inscrições</a>
            <a href="perfil.jsp">Meu Perfil</a>

        </nav>

        <div class="logout-area">
            <a href="<%= request.getContextPath() %>/paginas/logout.jsp" class="logout-btn">
                Terminar sessão
            </a>
        </div>

    </aside>

    <!-- CONTEÚDO PRINCIPAL -->
    <main class="main-content">

        <!-- TOPO -->
        <header class="topbar">

            <div class="search-box">
                <input type="text" placeholder="Pesquisar no painel do coordenador...">
            </div>

            <div class="topbar-right">
                <div class="user-box">

                    <div class="user-avatar">
                        <%= letraAvatar %>
                    </div>

                    <div class="user-info">
                        <strong><%= nomeCoordenador %></strong>
                        <span>Coordenador</span>
                    </div>

                </div>
            </div>

        </header>

        <!-- TÍTULO -->
        <section class="page-header">
            <h1>Dashboard do Coordenador</h1>
            <p>
                Bem-vindo ao painel do coordenador. Aqui podes acompanhar as tuas disciplinas,
                turmas, períodos de inscrição e inscrições dos alunos.
            </p>
        </section>

        <!-- CARTÕES -->
        <section class="cards-grid">

            <div class="info-card blue">
                <h3>Disciplinas</h3>
                <p><%= totalDisciplinas %></p>
            </div>

            <div class="info-card green">
                <h3>Turmas</h3>
                <p><%= totalTurmas %></p>
            </div>

            <div class="info-card orange">
                <h3>Inscrições</h3>
                <p><%= totalInscricoes %></p>
            </div>

            <div class="info-card pink">
                <h3>Períodos</h3>
                <p><%= totalPeriodos %></p>
            </div>

        </section>

        <!-- DADOS DO COORDENADOR -->
        <section class="profile-section">

            <div class="profile-card">

                <h2>Dados do Coordenador</h2>

                <div class="profile-grid">

                    <div class="profile-item">
                        <span>Nome completo</span>
                        <strong><%= nomeCoordenador %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Email</span>
                        <strong><%= emailCoordenador %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Curso</span>
                        <strong><%= cursoCoordenador %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Perfil</span>
                        <strong>Coordenador</strong>
                    </div>

                    <div class="profile-item">
                        <span>Total de disciplinas</span>
                        <strong><%= totalDisciplinas %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Total de inscrições</span>
                        <strong><%= totalInscricoes %></strong>
                    </div>

                </div>

            </div>

        </section>

        <!-- ÁREA DE RESPONSABILIDADES -->
        <section class="profile-section">

            <div class="profile-card">

                <h2>Área do Coordenador</h2>

                <div class="profile-grid">

                    <div class="profile-item">
                        <span>Minhas disciplinas</span>
                        <strong>Consultar disciplinas associadas ao coordenador</strong>
                    </div>

                    <div class="profile-item">
                        <span>Gestão de turmas</span>
                        <strong>Consultar e gerir turmas das suas disciplinas</strong>
                    </div>

                    <div class="profile-item">
                        <span>Períodos de inscrição</span>
                        <strong>Definir datas de inscrição por disciplina</strong>
                    </div>

                    <div class="profile-item">
                        <span>Inscrições</span>
                        <strong>Acompanhar alunos inscritos nas turmas</strong>
                    </div>

                    <div class="profile-item">
                        <span>Ocupação</span>
                        <strong>Ver vagas, capacidade e número de inscritos</strong>
                    </div>

                    <div class="profile-item">
                        <span>Perfil</span>
                        <strong>Consultar e atualizar dados pessoais</strong>
                    </div>

                </div>

            </div>

        </section>

    </main>

</div>

</body>
</html>