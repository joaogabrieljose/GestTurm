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

try {
    con = dbConnect();

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

} catch (Exception e) {
    out.print("Erro ao carregar dados do coordenador: " + e.getMessage());
}

String letraAvatar = "C";

if (nomeCoordenador != null && nomeCoordenador.trim().length() > 0) {
    letraAvatar = nomeCoordenador.substring(0, 1).toUpperCase();
}
%>

<%
/* =========================================
   MINHAS DISCIPLINAS
========================================= */
PreparedStatement psDisciplinas = null;
ResultSet rsDisciplinas = null;

try {
    psDisciplinas = con.prepareStatement(
        "SELECT " +
        "d.id, " +
        "d.nome, " +
        "d.codigo, " +
        "d.semestre, " +
        "d.ano_letivo, " +
        "d.numero_alunos_inscritos, " +
        "d.ativo, " +

        "COALESCE(t.total_turmas, 0) AS total_turmas, " +
        "COALESCE(i.total_inscricoes, 0) AS total_inscricoes, " +

        "CASE " +
        "   WHEN pi.ativo = 1 AND NOW() BETWEEN pi.data_inicio AND pi.data_fim " +
        "   THEN 'ABERTO' " +
        "   WHEN pi.id IS NULL " +
        "   THEN 'NÃO DEFINIDO' " +
        "   ELSE 'FECHADO' " +
        "END AS estado_periodo, " +

        "COALESCE(DATE_FORMAT(pi.data_inicio, '%d/%m/%Y %H:%i'), '-') AS data_inicio, " +
        "COALESCE(DATE_FORMAT(pi.data_fim, '%d/%m/%Y %H:%i'), '-') AS data_fim " +

        "FROM disciplinas d " +

        "LEFT JOIN ( " +
        "   SELECT disciplina_id, COUNT(*) AS total_turmas " +
        "   FROM turmas " +
        "   GROUP BY disciplina_id " +
        ") t ON t.disciplina_id = d.id " +

        "LEFT JOIN ( " +
        "   SELECT disciplina_id, COUNT(*) AS total_inscricoes " +
        "   FROM inscricoes " +
        "   WHERE estado = 'ATIVA' " +
        "   GROUP BY disciplina_id " +
        ") i ON i.disciplina_id = d.id " +

        "LEFT JOIN periodos_inscricao pi ON pi.disciplina_id = d.id " +

        "WHERE d.coordenador_id = ? " +
        "ORDER BY d.nome"
    );

    psDisciplinas.setInt(1, coordenadorId);
    rsDisciplinas = dbQuery(con, psDisciplinas);

} catch (Exception e) {
    out.print("Erro ao carregar disciplinas: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Minhas Disciplinas - Gesturma</title>
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
            <a href="coordenador.jsp">Dashboard</a>
            <a href="disciplinas.jsp" class="active">Minhas Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="gestao_inscricoes.jsp">Gestão de Inscrições</a>
            <a href="perfil.jsp"> Meu Perfil</a>
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
                <input type="text" placeholder="Pesquisar disciplinas..." disabled>
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
            <h1>Minhas Disciplinas</h1>
            <p>
                Consulta as disciplinas associadas ao teu perfil de coordenador.
            </p>
        </section>

        <!-- DADOS DO COORDENADOR -->
        <section class="profile-section">

            <div class="profile-card">

                <h2>Informação do Coordenador</h2>

                <div class="profile-grid">

                    <div class="profile-item">
                        <span>Nome</span>
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

                </div>

            </div>

        </section>

        <!-- LISTA DE DISCIPLINAS -->
        <section class="profile-section">

            <div class="profile-card">

                <div class="crud-header">
                    <h2>Disciplinas Associadas</h2>
                </div>

                <div class="table-wrapper">

                    <table class="crud-table">
                        <thead>
                            <tr>
                                <th>Disciplina</th>
                                <th>Código</th>
                                <th>Semestre</th>
                                <th>Ano Letivo</th>
                                <th>Alunos previstos</th>
                                <th>Turmas</th>
                                <th>Inscrições ativas</th>
                                <th>Período</th>
                                <th>Estado</th>
                            </tr>
                        </thead>

                        <tbody>

                        <%
                            boolean temDisciplinas = false;

                            if (rsDisciplinas != null) {
                                while (rsDisciplinas.next()) {
                                    temDisciplinas = true;

                                    int ativo = rsDisciplinas.getInt("ativo");
                                    String estadoTexto = ativo == 1 ? "Ativa" : "Inativa";
                                    String estadoClasse = ativo == 1 ? "estado-ativo" : "estado-inativo";

                                    String estadoPeriodo = rsDisciplinas.getString("estado_periodo");
                                    String classePeriodo = "estado-alterada";

                                    if ("ABERTO".equalsIgnoreCase(estadoPeriodo)) {
                                        classePeriodo = "estado-ativo";
                                    } else if ("FECHADO".equalsIgnoreCase(estadoPeriodo)) {
                                        classePeriodo = "estado-inativo";
                                    }
                        %>

                            <tr>
                                <td><%= rsDisciplinas.getString("nome") %></td>

                                <td>
                                    <span class="perfil-badge">
                                        <%= rsDisciplinas.getString("codigo") %>
                                    </span>
                                </td>

                                <td><%= rsDisciplinas.getInt("semestre") %>º Semestre</td>

                                <td><%= rsDisciplinas.getString("ano_letivo") %></td>

                                <td><%= rsDisciplinas.getInt("numero_alunos_inscritos") %></td>

                                <td><%= rsDisciplinas.getInt("total_turmas") %></td>

                                <td><%= rsDisciplinas.getInt("total_inscricoes") %></td>

                                <td>
                                    <span class="<%= classePeriodo %>">
                                        <%= estadoPeriodo %>
                                    </span>
                                    <br>
                                    <small>
                                        <%= rsDisciplinas.getString("data_inicio") %>
                                        até
                                        <%= rsDisciplinas.getString("data_fim") %>
                                    </small>
                                </td>

                                <td>
                                    <span class="<%= estadoClasse %>">
                                        <%= estadoTexto %>
                                    </span>
                                </td>
                            </tr>

                        <%
                                }
                            }

                            if (!temDisciplinas) {
                        %>

                            <tr>
                                <td colspan="9" class="empty-table-message">
                                    Não existem disciplinas associadas a este coordenador.
                                </td>
                            </tr>

                        <%
                            }
                        %>

                        </tbody>
                    </table>

                </div>

            </div>

        </section>

    </main>

</div>

<%
    dbClose(rsDisciplinas, psDisciplinas, con);
%>

</body>
</html>