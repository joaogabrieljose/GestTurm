<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"ADMINISTRADOR".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT " +
        "t.id, t.nome AS turma, t.tipo, t.capacidade_minima, t.capacidade_maxima, t.ativo, " +
        "d.nome AS disciplina, d.codigo AS codigo_disciplina, " +
        "COALESCE(ins.total_inscritos, 0) AS total_inscritos, " +
        "COALESCE(h.lista_horarios, 'Horário ainda não definido') AS horario " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
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
        "ORDER BY t.id DESC"
    );

    rs = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar turmas: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Gestão de Turmas - Gesturma</title>
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
            <a href="admin.jsp">Dashboard</a>
            <a href="utilizadores.jsp">Gestão Utilizadores</a>
            <a href="disciplinas.jsp">Gestão de Disciplinas</a>
            <a href="turmas.jsp" class="active">Gestão de Turmas</a>
            <a href="inscricoes.jsp">Gestão de Inscrições</a>
            <a href="#" id="abrirPerfilLink"> Meu Perfil</a>
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
                <input type="text" placeholder="Pesquisar turmas...">
            </div>

            <div class="topbar-right">
                <div class="user-box">
                    <div class="user-avatar">A</div>
                    <div class="user-info">
                        <strong>Administrador</strong>
                        <span>Gestão de Turmas</span>
                    </div>
                </div>
            </div>
        </header>

        <section class="page-header">
            <h1>Gestão de Turmas</h1>
            <p>Criação, consulta, edição e eliminação de turmas e horários.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <div class="crud-header">
                    <h2>Lista de Turmas</h2>

                    <a href="turma_criar.jsp" class="crud-btn">
                        + Nova Turma
                    </a>
                </div>

                <div class="table-wrapper">

                    <table class="crud-table">
                        <thead>
                            <tr>
                                <th>Turma</th>
                                <th>Disciplina</th>
                                <th>Tipo</th>
                                <th>Capacidade</th>
                                <th>Inscritos</th>
                                <th>Horário</th>
                                <th>Estado</th>
                                <th>Ações</th>
                            </tr>
                        </thead>

                        <tbody>

                        <%
                            boolean temTurmas = false;

                            if (rs != null) {
                                while (rs.next()) {
                                    temTurmas = true;

                                    int ativo = rs.getInt("ativo");
                                    String estadoTexto = ativo == 1 ? "Ativa" : "Inativa";
                                    String estadoClasse = ativo == 1 ? "estado-ativo" : "estado-inativo";
                        %>

                            <tr>
                                <td><%= rs.getString("turma") %></td>
                                <td>
                                    <%= rs.getString("disciplina") %>
                                    (<%= rs.getString("codigo_disciplina") %>)
                                </td>
                                <td><%= rs.getString("tipo").replace("_", " ") %></td>
                                <td>
                                    Min: <%= rs.getInt("capacidade_minima") %><br>
                                    Máx: <%= rs.getInt("capacidade_maxima") %>
                                </td>
                                <td><%= rs.getInt("total_inscritos") %></td>
                                <td><%= rs.getString("horario") %></td>
                                <td>
                                    <span class="<%= estadoClasse %>">
                                        <%= estadoTexto %>
                                    </span>
                                </td>
                                <td>
                                    <a href="turma_editar.jsp?id=<%= rs.getInt("id") %>" class="btn-editar">
                                        Editar
                                    </a>

                                    <a 
                                        href="turma_eliminar.jsp?id=<%= rs.getInt("id") %>" 
                                        class="btn-eliminar"
                                        onclick="return confirm('Tens a certeza que queres eliminar/inativar esta turma?');"
                                    >
                                        Eliminar
                                    </a>
                                </td>
                            </tr>

                        <%
                                }
                            }

                            if (!temTurmas) {
                        %>

                            <tr>
                                <td colspan="8" class="empty-table-message">
                                    Ainda não existem turmas registadas.
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