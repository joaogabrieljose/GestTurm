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
        "d.id, d.nome, d.codigo, d.semestre, d.ano_letivo, " +
        "d.numero_alunos_inscritos, d.ativo, " +
        "u.nome AS coordenador_nome, " +
        "c.curso AS coordenador_curso " +
        "FROM disciplinas d " +
        "INNER JOIN coordenadores c ON c.id = d.coordenador_id " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "ORDER BY d.id DESC"
    );

    rs = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar disciplinas: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Gestão de Disciplinas - Gesturma</title>
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
            <a href="disciplinas.jsp" class="active">Gestão de Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="inscricoes.jsp">Gestão de Inscrições</a>
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
                <input type="text" placeholder="Pesquisar disciplinas...">
            </div>

            <div class="topbar-right">
                <div class="user-box">
                    <div class="user-avatar">A</div>
                    <div class="user-info">
                        <strong>Administrador</strong>
                        <span>Gestão de Disciplinas</span>
                    </div>
                </div>
            </div>
        </header>

        <section class="page-header">
            <h1>Gestão de Disciplinas</h1>
            <p>Criação, consulta, edição e eliminação de disciplinas do sistema.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <div class="crud-header">
                    <h2>Lista de Disciplinas</h2>

                    <a href="disciplina_criar.jsp" class="crud-btn">
                        + Nova Disciplina
                    </a>
                </div>

                <div class="table-wrapper">

                    <table class="crud-table">
                        <thead>
                            <tr>
                                <th>Nome</th>
                                <th>Código</th>
                                <th>Coordenador</th>
                                <th>Curso</th>
                                <th>Semestre</th>
                                <th>Ano letivo</th>
                                <th>Nº alunos</th>
                                <th>Estado</th>
                                <th>Ações</th>
                            </tr>
                        </thead>

                        <tbody>

                        <%
                            boolean temDisciplinas = false;

                            if (rs != null) {
                                while (rs.next()) {
                                    temDisciplinas = true;

                                    int ativo = rs.getInt("ativo");
                                    String estadoTexto = ativo == 1 ? "Ativa" : "Inativa";
                                    String estadoClasse = ativo == 1 ? "estado-ativo" : "estado-inativo";
                        %>

                            <tr>
                                <td><%= rs.getString("nome") %></td>
                                <td><%= rs.getString("codigo") %></td>
                                <td><%= rs.getString("coordenador_nome") %></td>
                                <td><%= rs.getString("coordenador_curso") %></td>
                                <td><%= rs.getInt("semestre") %></td>
                                <td><%= rs.getString("ano_letivo") %></td>
                                <td><%= rs.getInt("numero_alunos_inscritos") %></td>
                                <td>
                                    <span class="<%= estadoClasse %>">
                                        <%= estadoTexto %>
                                    </span>
                                </td>
                                <td>
                                    <a href="disciplina_editar.jsp?id=<%= rs.getInt("id") %>" class="btn-editar">
                                        Editar
                                    </a>

                                    <a 
                                        href="disciplina_eliminar.jsp?id=<%= rs.getInt("id") %>" 
                                        class="btn-eliminar"
                                        onclick="return confirm('Tens a certeza que queres eliminar/inativar esta disciplina?');"
                                    >
                                        Eliminar
                                    </a>
                                </td>
                            </tr>

                        <%
                                }
                            }

                            if (!temDisciplinas) {
                        %>

                            <tr>
                                <td colspan="9" class="empty-table-message">
                                    Ainda não existem disciplinas registadas.
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