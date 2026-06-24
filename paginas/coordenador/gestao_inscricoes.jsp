<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"COORDENADOR".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

int coordenadorId = 0;
String nomeCoordenador = "";

int totalDisciplinas = 0;
int totalPeriodos = 0;
int totalInscricoes = 0;
int totalInscricoesAtivas = 0;
int totalTurmas = 0;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT c.id AS coordenador_id, u.nome " +
        "FROM coordenadores c " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE u.id = ? AND u.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        coordenadorId = rs.getInt("coordenador_id");
        nomeCoordenador = rs.getString("nome");
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=coordenador_nao_encontrado");
        return;
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM disciplinas " +
        "WHERE coordenador_id = ?"
    );
    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);
    if (rs.next()) totalDisciplinas = rs.getInt("total");

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM periodos_inscricao pi " +
        "INNER JOIN disciplinas d ON d.id = pi.disciplina_id " +
        "WHERE d.coordenador_id = ?"
    );
    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);
    if (rs.next()) totalPeriodos = rs.getInt("total");

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM inscricoes i " +
        "INNER JOIN disciplinas d ON d.id = i.disciplina_id " +
        "WHERE d.coordenador_id = ?"
    );
    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);
    if (rs.next()) totalInscricoes = rs.getInt("total");

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM inscricoes i " +
        "INNER JOIN disciplinas d ON d.id = i.disciplina_id " +
        "WHERE d.coordenador_id = ? " +
        "AND i.estado = 'ATIVA'"
    );
    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);
    if (rs.next()) totalInscricoesAtivas = rs.getInt("total");

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "WHERE d.coordenador_id = ?"
    );
    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);
    if (rs.next()) totalTurmas = rs.getInt("total");

} catch (Exception e) {
    out.print("Erro ao carregar gestão de inscrições: " + e.getMessage());

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
    <title>Gestão de Inscrições - Coordenador</title>
    <link rel="stylesheet" href="../../css/geral.css">
</head>

<body>

<div class="dashboard-container">

    <aside class="sidebar">

        <div class="brand">
            <div class="brand-icon">G</div>
            <span>Gesturma</span>
        </div>

        <nav class="menu">
            <a href="coordenador.jsp"> Dashboard</a>
            <a href="disciplinas.jsp">Minhas Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="gestao_inscricoes.jsp" class="active">Gestão de Inscrições</a>
            <a href="perfil.jsp">Meu Perfil</a>
        </nav>

        <div class="logout-area">
            <a href="<%= request.getContextPath() %>/paginas/logout.jsp" class="logout-btn">
                Terminar sessão
            </a>
        </div>

    </aside>

    <main class="main-content">

        <header class="topbar">

            <div class="search-box">
                <input type="text" placeholder="Gestão de inscrições" disabled>
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

        <section class="page-header">
            <h1>Gestão de Inscrições</h1>
        </section>

        <section class="profile-section">

            <div class="profile-card">

                <h2>Fluxo de inscrições </h2>

                <div class="profile-grid">

                    <div class="profile-item">
                        <span>Períodos de Inscrição</span>
                        <br><br>
                        <a href="periodos.jsp" class="crud-btn">
                            Gerir Períodos
                        </a>
                    </div>

                    <div class="profile-item">
                        <span>Inscrições dos Alunos</span>
                        <br><br>
                        <a href="inscricoes.jsp" class="crud-btn">
                            Gerir Inscrições
                        </a>
                    </div>

                    <div class="profile-item">
                        <span>Controlo de Vagas</span>
                        <br><br>
                        <a href="vagas.jsp" class="crud-btn">
                            Ver Vagas
                        </a>
                    </div>

                    <div class="profile-item">
                        <span>Estado das Inscrições</span>
                        <br><br>
                        <a href="inscricoes.jsp" class="crud-btn">
                            Consultar Estados
                        </a>
                    </div>

                </div>

            </div>

        </section>

    </main>

</div>

</body>
</html>