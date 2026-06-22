<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
/* =========================================
   PROTEÇÃO DE ACESSO
========================================= */
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"ALUNO".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());

/* =========================================
   DADOS DO ALUNO
========================================= */
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String nomeAluno = "";
String emailAluno = "";
String numeroAluno = "";
String cursoAluno = "";
int anoCurricular = 0;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT " +
        "u.nome, u.email, " +
        "a.numero_aluno, a.curso, a.ano_curricular " +
        "FROM utilizadores u " +
        "INNER JOIN alunos a ON a.utilizador_id = u.id " +
        "WHERE u.id = ? " +
        "LIMIT 1"
    );

    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        nomeAluno = rs.getString("nome");
        emailAluno = rs.getString("email");
        numeroAluno = rs.getString("numero_aluno");
        cursoAluno = rs.getString("curso");
        anoCurricular = rs.getInt("ano_curricular");
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=aluno_nao_encontrado");
        return;
    }

} catch (Exception e) {
    out.print("Erro ao carregar os dados do aluno: " + e.getMessage());
} finally {
    dbClose(rs, ps, con);
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Aluno - Gesturma</title>
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
            <a href="aluno.jsp" class="active">Dashboard</a>
            <a href="#">Minhas Inscrições</a>
            <a href="#">Turmas Disponíveis</a>
            <a href="#">Horários</a>
            <a href="#">Meu Perfil</a>
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
                <input type="text" placeholder="Pesquisar...">
            </div>

            <div class="topbar-right">
                <div class="notification"></div>
                <div class="user-box">
                    <div class="user-avatar">
                        <%= nomeAluno.substring(0,1).toUpperCase() %>
                    </div>
                    <div class="user-info">
                        <strong><%= nomeAluno %></strong>
                        <span>Aluno</span>
                    </div>
                </div>
            </div>
        </header>

        <!-- TÍTULO -->
        <section class="page-header">
            <h1>Dashboard do Aluno</h1>
            <p>Bem-vindo ao Gesturma. Aqui podes acompanhar os teus dados académicos.</p>
        </section>

        <!-- CARTÕES -->
        <section class="cards-grid">
            <div class="info-card blue">
                <h3>Nome</h3>
                <p><%= nomeAluno %></p>
            </div>

            <div class="info-card green">
                <h3>Número de Aluno</h3>
                <p><%= numeroAluno %></p>
            </div>

            <div class="info-card orange">
                <h3>Curso</h3>
                <p><%= cursoAluno %></p>
            </div>

            <div class="info-card pink">
                <h3>Ano Curricular</h3>
                <p><%= anoCurricular %>º Ano</p>
            </div>
        </section>

        <!-- PERFIL -->
        <section class="profile-section">
            <div class="profile-card">
                <h2>Dados do Aluno</h2>

                <div class="profile-grid">
                    <div class="profile-item">
                        <span>Nome completo</span>
                        <strong><%= nomeAluno %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Email</span>
                        <strong><%= emailAluno %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Número de aluno</span>
                        <strong><%= numeroAluno %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Curso</span>
                        <strong><%= cursoAluno %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Ano curricular</span>
                        <strong><%= anoCurricular %>º Ano</strong>
                    </div>

                    <div class="profile-item">
                        <span>Perfil</span>
                        <strong>Aluno</strong>
                    </div>
                </div>
            </div>
        </section>
    </main>
</div>

</body>
</html>