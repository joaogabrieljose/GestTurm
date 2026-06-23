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
        "i.id, i.estado, " +
        "DATE_FORMAT(i.data_inscricao, '%d/%m/%Y %H:%i') AS data_inscricao, " +
        "u.nome AS aluno_nome, " +
        "a.numero_aluno, " +
        "d.nome AS disciplina, " +
        "d.codigo AS codigo_disciplina, " +
        "t.nome AS turma, " +
        "t.tipo, " +
        "COALESCE(h.lista_horarios, 'Horário ainda não definido') AS horario " +
        "FROM inscricoes i " +
        "INNER JOIN alunos a ON a.id = i.aluno_id " +
        "INNER JOIN utilizadores u ON u.id = a.utilizador_id " +
        "INNER JOIN disciplinas d ON d.id = i.disciplina_id " +
        "INNER JOIN turmas t ON t.id = i.turma_id " +
        "LEFT JOIN ( " +
        "   SELECT turma_id, " +
        "   GROUP_CONCAT(CONCAT(dia_semana, ' ', TIME_FORMAT(hora_inicio, '%H:%i'), ' - ', TIME_FORMAT(hora_fim, '%H:%i'), ' | ', sala) SEPARATOR ' / ') AS lista_horarios " +
        "   FROM horarios " +
        "   GROUP BY turma_id " +
        ") h ON h.turma_id = t.id " +
        "ORDER BY i.id DESC"
    );

    rs = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar inscrições: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Gestão de Inscrições - Gesturma</title>
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
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="inscricoes.jsp" class="active">Gestão de Inscrições</a>
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
                <input type="text" placeholder="Pesquisar inscrições...">
            </div>

            <div class="topbar-right">
                <div class="user-box">
                    <div class="user-avatar">A</div>
                    <div class="user-info">
                        <strong>Administrador</strong>
                        <span>Gestão de Inscrições</span>
                    </div>
                </div>
            </div>
        </header>

        <section class="page-header">
            <h1>Gestão de Inscrições</h1>
            <p>Criação, consulta, edição e cancelamento de inscrições dos alunos.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <div class="crud-header">
                    <h2>Lista de Inscrições</h2>

                    <a href="inscricao_criar.jsp" class="crud-btn">
                        + Nova Inscrição
                    </a>
                </div>

                <div class="table-wrapper">

                    <table class="crud-table">
                        <thead>
                            <tr>
                                <th>Aluno</th>
                                <th>Nº Aluno</th>
                                <th>Disciplina</th>
                                <th>Turma</th>
                                <th>Tipo</th>
                                <th>Horário</th>
                                <th>Estado</th>
                                <th>Data</th>
                                <th>Ações</th>
                            </tr>
                        </thead>

                        <tbody>

                        <%
                            boolean temInscricoes = false;

                            if (rs != null) {
                                while (rs.next()) {
                                    temInscricoes = true;

                                    String estado = rs.getString("estado");
                                    String estadoClasse = "estado-alterada";

                                    if ("ATIVA".equalsIgnoreCase(estado)) {
                                        estadoClasse = "estado-ativo";
                                    } else if ("CANCELADA".equalsIgnoreCase(estado)) {
                                        estadoClasse = "estado-inativo";
                                    }
                        %>

                            <tr>
                                <td><%= rs.getString("aluno_nome") %></td>
                                <td><%= rs.getString("numero_aluno") %></td>
                                <td>
                                    <%= rs.getString("disciplina") %>
                                    (<%= rs.getString("codigo_disciplina") %>)
                                </td>
                                <td><%= rs.getString("turma") %></td>
                                <td><%= rs.getString("tipo").replace("_", " ") %></td>
                                <td><%= rs.getString("horario") %></td>
                                <td>
                                    <span class="<%= estadoClasse %>">
                                        <%= estado %>
                                    </span>
                                </td>
                                <td><%= rs.getString("data_inscricao") %></td>
                                <td>
                                    <a href="inscricao_editar.jsp?id=<%= rs.getInt("id") %>" class="btn-editar">
                                        Editar
                                    </a>

                                    <a 
                                        href="inscricao_eliminar.jsp?id=<%= rs.getInt("id") %>" 
                                        class="btn-eliminar"
                                        onclick="return confirm('Tens a certeza que queres cancelar esta inscrição?');"
                                    >
                                        Cancelar
                                    </a>
                                </td>
                            </tr>

                        <%
                                }
                            }

                            if (!temInscricoes) {
                        %>

                            <tr>
                                <td colspan="9" class="empty-table-message">
                                    Ainda não existem inscrições registadas.
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