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

int totalTurmas = 0;
int totalVagas = 0;
int turmasComVagas = 0;
int turmasLotadas = 0;

try {
    con = dbConnect();

    /* Buscar coordenador autenticado */
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

    /* Resumo das vagas */
    ps = con.prepareStatement(
        "SELECT " +
        "COUNT(*) AS total_turmas, " +
        "SUM(GREATEST(t.capacidade_maxima - COALESCE(ins.total_inscritos, 0), 0)) AS total_vagas, " +
        "SUM(CASE WHEN (t.capacidade_maxima - COALESCE(ins.total_inscritos, 0)) > 0 THEN 1 ELSE 0 END) AS turmas_com_vagas, " +
        "SUM(CASE WHEN (t.capacidade_maxima - COALESCE(ins.total_inscritos, 0)) <= 0 THEN 1 ELSE 0 END) AS turmas_lotadas " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "LEFT JOIN ( " +
        "   SELECT turma_id, COUNT(*) AS total_inscritos " +
        "   FROM inscricoes " +
        "   WHERE estado = 'ATIVA' " +
        "   GROUP BY turma_id " +
        ") ins ON ins.turma_id = t.id " +
        "WHERE d.coordenador_id = ? " +
        "AND d.ativo = 1 " +
        "AND t.ativo = 1"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        totalTurmas = rs.getInt("total_turmas");
        totalVagas = rs.getInt("total_vagas");
        turmasComVagas = rs.getInt("turmas_com_vagas");
        turmasLotadas = rs.getInt("turmas_lotadas");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    /* Lista detalhada das vagas */
    ps = con.prepareStatement(
        "SELECT " +
        "d.nome AS disciplina, " +
        "d.codigo AS codigo_disciplina, " +
        "t.id AS turma_id, " +
        "t.nome AS turma, " +
        "t.tipo, " +
        "t.capacidade_minima, " +
        "t.capacidade_maxima, " +
        "COALESCE(ins.total_inscritos, 0) AS total_inscritos, " +
        "GREATEST(t.capacidade_maxima - COALESCE(ins.total_inscritos, 0), 0) AS vagas_disponiveis, " +
        "CASE " +
        "   WHEN t.capacidade_maxima > 0 THEN ROUND((COALESCE(ins.total_inscritos, 0) / t.capacidade_maxima) * 100, 0) " +
        "   ELSE 0 " +
        "END AS ocupacao_percentagem, " +
        "COALESCE(h.lista_horarios, 'Horário ainda não definido') AS horario, " +
        "CASE " +
        "   WHEN (t.capacidade_maxima - COALESCE(ins.total_inscritos, 0)) <= 0 THEN 'LOTADA' " +
        "   WHEN (t.capacidade_maxima - COALESCE(ins.total_inscritos, 0)) <= 5 THEN 'POUCAS VAGAS' " +
        "   ELSE 'COM VAGAS' " +
        "END AS estado_vagas, " +
        "CASE " +
        "   WHEN pi.id IS NULL THEN 'NÃO DEFINIDO' " +
        "   WHEN pi.ativo = 0 THEN 'INATIVO' " +
        "   WHEN NOW() < pi.data_inicio THEN 'AGENDADO' " +
        "   WHEN NOW() BETWEEN pi.data_inicio AND pi.data_fim THEN 'ABERTO' " +
        "   ELSE 'FECHADO' " +
        "END AS estado_periodo " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "LEFT JOIN periodos_inscricao pi ON pi.disciplina_id = d.id " +
        "LEFT JOIN ( " +
        "   SELECT turma_id, COUNT(*) AS total_inscritos " +
        "   FROM inscricoes " +
        "   WHERE estado = 'ATIVA' " +
        "   GROUP BY turma_id " +
        ") ins ON ins.turma_id = t.id " +
        "LEFT JOIN ( " +
        "   SELECT turma_id, " +
        "   GROUP_CONCAT(CONCAT(dia_semana, ' ', TIME_FORMAT(hora_inicio, '%H:%i'), ' - ', TIME_FORMAT(hora_fim, '%H:%i'), ' | ', sala) SEPARATOR ' / ') AS lista_horarios " +
        "   FROM horarios " +
        "   GROUP BY turma_id " +
        ") h ON h.turma_id = t.id " +
        "WHERE d.coordenador_id = ? " +
        "AND d.ativo = 1 " +
        "AND t.ativo = 1 " +
        "ORDER BY d.nome, t.nome"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar vagas: " + e.getMessage());
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
    <title>Ver Vagas - Gesturma</title>
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
            <a href="coordenador.jsp">Dashboard</a>
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
                <input type="text" placeholder="Ver vagas das turmas" disabled>
            </div>

            <div class="topbar-right">
                <div class="user-box">
                    <div class="user-avatar"><%= letraAvatar %></div>

                    <div class="user-info">
                        <strong><%= nomeCoordenador %></strong>
                        <span>Coordenador</span>
                    </div>
                </div>
            </div>
        </header>

        <section class="page-header">
            <h1>Ver Vagas</h1>
            <p>
                Consulta a ocupação das turmas, vagas disponíveis e estado dos períodos de inscrição.
            </p>
        </section>

        <section class="cards-grid">

            <div class="info-card blue">
                <h3>Total de Turmas</h3>
                <p><%= totalTurmas %></p>
            </div>

            <div class="info-card green">
                <h3>Total de Vagas</h3>
                <p><%= totalVagas %></p>
            </div>

            <div class="info-card orange">
                <h3>Turmas com Vagas</h3>
                <p><%= turmasComVagas %></p>
            </div>

            <div class="info-card pink">
                <h3>Turmas Lotadas</h3>
                <p><%= turmasLotadas %></p>
            </div>

        </section>

        <section class="profile-section">

            <div class="profile-card">

                <div class="crud-header">
                    <h2>Vagas por Turma</h2>

                    <a href="gestao_inscricoes.jsp" class="btn-voltar">
                        Voltar
                    </a>
                </div>

                <div class="table-wrapper">

                    <table class="crud-table">
                        <thead>
                            <tr>
                                <th>Disciplina</th>
                                <th>Turma</th>
                                <th>Tipo</th>
                                <th>Capacidade</th>
                                <th>Inscritos</th>
                                <th>Vagas</th>
                                <th>Ocupação</th>
                                <th>Horário</th>
                                <th>Estado Vagas</th>
                                <th>Período</th>
                            </tr>
                        </thead>

                        <tbody>

                        <%
                            boolean temVagas = false;

                            if (rs != null) {
                                while (rs.next()) {
                                    temVagas = true;

                                    String estadoVagas = rs.getString("estado_vagas");
                                    String classeVagas = "estado-ativo";

                                    if ("LOTADA".equalsIgnoreCase(estadoVagas)) {
                                        classeVagas = "estado-inativo";
                                    } else if ("POUCAS VAGAS".equalsIgnoreCase(estadoVagas)) {
                                        classeVagas = "estado-alterada";
                                    }

                                    String estadoPeriodo = rs.getString("estado_periodo");
                                    String classePeriodo = "estado-alterada";

                                    if ("ABERTO".equalsIgnoreCase(estadoPeriodo)) {
                                        classePeriodo = "estado-ativo";
                                    } else if ("FECHADO".equalsIgnoreCase(estadoPeriodo) || "INATIVO".equalsIgnoreCase(estadoPeriodo)) {
                                        classePeriodo = "estado-inativo";
                                    }
                        %>

                            <tr>
                                <td>
                                    <%= rs.getString("disciplina") %>
                                    (<%= rs.getString("codigo_disciplina") %>)
                                </td>

                                <td><%= rs.getString("turma") %></td>

                                <td><%= rs.getString("tipo").replace("_", " ") %></td>

                                <td>
                                    Min: <%= rs.getInt("capacidade_minima") %><br>
                                    Máx: <%= rs.getInt("capacidade_maxima") %>
                                </td>

                                <td><%= rs.getInt("total_inscritos") %></td>

                                <td>
                                    <strong><%= rs.getInt("vagas_disponiveis") %></strong>
                                </td>

                                <td>
                                    <%= rs.getInt("ocupacao_percentagem") %>%
                                </td>

                                <td><%= rs.getString("horario") %></td>

                                <td>
                                    <span class="<%= classeVagas %>">
                                        <%= estadoVagas %>
                                    </span>
                                </td>

                                <td>
                                    <span class="<%= classePeriodo %>">
                                        <%= estadoPeriodo %>
                                    </span>
                                </td>
                            </tr>

                        <%
                                }
                            }

                            if (!temVagas) {
                        %>

                            <tr>
                                <td colspan="10" class="empty-table-message">
                                    Ainda não existem turmas ativas para consultar vagas.
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
    dbClose(rs, ps, con);
%>

</body>
</html>