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
        "SELECT " +
        "pi.id, pi.ativo, " +
        "DATE_FORMAT(pi.data_inicio, '%d/%m/%Y %H:%i') AS data_inicio, " +
        "DATE_FORMAT(pi.data_fim, '%d/%m/%Y %H:%i') AS data_fim, " +
        "d.nome AS disciplina, d.codigo AS codigo_disciplina, " +
        "d.semestre, d.ano_letivo, " +
        "CASE " +
        "   WHEN pi.ativo = 0 THEN 'INATIVO' " +
        "   WHEN NOW() < pi.data_inicio THEN 'AGENDADO' " +
        "   WHEN NOW() BETWEEN pi.data_inicio AND pi.data_fim THEN 'ABERTO' " +
        "   ELSE 'FECHADO' " +
        "END AS estado_periodo " +
        "FROM periodos_inscricao pi " +
        "INNER JOIN disciplinas d ON d.id = pi.disciplina_id " +
        "WHERE d.coordenador_id = ? " +
        "ORDER BY pi.data_inicio DESC"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar períodos: " + e.getMessage());
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
    <title>Gerir Períodos - Gesturma</title>
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
                <input type="text" placeholder="Gerir períodos de inscrição" disabled>
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
            <h1>Gerir Períodos de Inscrição</h1>
            <p>
                Define quando os alunos podem inscrever-se nas disciplinas associadas ao teu perfil.
            </p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <div class="crud-header">
                    <h2>Lista de Períodos</h2>

                    <a href="periodo_criar.jsp" class="crud-btn">
                        + Novo Período
                    </a>
                </div>

                <div class="table-wrapper">

                    <table class="crud-table">
                        <thead>
                            <tr>
                                <th>Disciplina</th>
                                <th>Código</th>
                                <th>Semestre</th>
                                <th>Ano Letivo</th>
                                <th>Data Início</th>
                                <th>Data Fim</th>
                                <th>Estado</th>
                                <th>Ativo</th>
                                <th>Ações</th>
                            </tr>
                        </thead>

                        <tbody>

                        <%
                            boolean temPeriodos = false;

                            if (rs != null) {
                                while (rs.next()) {
                                    temPeriodos = true;

                                    int ativo = rs.getInt("ativo");
                                    String ativoTexto = ativo == 1 ? "Ativo" : "Inativo";
                                    String ativoClasse = ativo == 1 ? "estado-ativo" : "estado-inativo";

                                    String estadoPeriodo = rs.getString("estado_periodo");
                                    String estadoPeriodoClasse = "estado-alterada";

                                    if ("ABERTO".equalsIgnoreCase(estadoPeriodo)) {
                                        estadoPeriodoClasse = "estado-ativo";
                                    } else if ("FECHADO".equalsIgnoreCase(estadoPeriodo) || "INATIVO".equalsIgnoreCase(estadoPeriodo)) {
                                        estadoPeriodoClasse = "estado-inativo";
                                    }
                        %>

                            <tr>
                                <td><%= rs.getString("disciplina") %></td>

                                <td>
                                    <span class="perfil-badge">
                                        <%= rs.getString("codigo_disciplina") %>
                                    </span>
                                </td>

                                <td><%= rs.getInt("semestre") %>º Semestre</td>

                                <td><%= rs.getString("ano_letivo") %></td>

                                <td><%= rs.getString("data_inicio") %></td>

                                <td><%= rs.getString("data_fim") %></td>

                                <td>
                                    <span class="<%= estadoPeriodoClasse %>">
                                        <%= estadoPeriodo %>
                                    </span>
                                </td>

                                <td>
                                    <span class="<%= ativoClasse %>">
                                        <%= ativoTexto %>
                                    </span>
                                </td>

                                <td>
                                    <a href="periodo_editar.jsp?id=<%= rs.getInt("id") %>" class="btn-editar">
                                        Editar
                                    </a>

                                    <a 
                                        href="periodo_eliminar.jsp?id=<%= rs.getInt("id") %>" 
                                        class="btn-eliminar"
                                        onclick="return confirm('Tens a certeza que queres inativar este período?');"
                                    >
                                        Eliminar
                                    </a>
                                </td>
                            </tr>

                        <%
                                }
                            }

                            if (!temPeriodos) {
                        %>

                            <tr>
                                <td colspan="9" class="empty-table-message">
                                    Ainda não existem períodos registados.
                                </td>
                            </tr>

                        <%
                            }
                        %>

                        </tbody>
                    </table>

                </div>

                <div class="form-actions">
                    <a href="gestao_inscricoes.jsp" class="btn-voltar">
                        Voltar
                    </a>
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