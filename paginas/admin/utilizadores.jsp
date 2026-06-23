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
        "u.id, u.nome, u.email, u.perfil, u.ativo, " +
        "DATE_FORMAT(u.criado_em, '%d/%m/%Y %H:%i') AS criado_em, " +
        "COALESCE(a.numero_aluno, '-') AS numero_aluno, " +
        "COALESCE(a.curso, c.curso, '-') AS curso " +
        "FROM utilizadores u " +
        "LEFT JOIN alunos a ON a.utilizador_id = u.id " +
        "LEFT JOIN coordenadores c ON c.utilizador_id = u.id " +
        "ORDER BY u.id DESC"
    );

    rs = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar utilizadores: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Gestão de Utilizadores - Gesturma</title>
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

            <a href="utilizadores.jsp" class="active">Gestão Utilizadores</a>
            <a href="disciplinas.jsp"> Gestão de Disciplinas</a>
            <a href="turmas.jsp"> Gestão de Turmas</a>
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
                <input type="text" placeholder="Pesquisar utilizadores...">
            </div>

            <div class="topbar-right">
                <div class="user-box">
                    <div class="user-avatar">A</div>
                    <div class="user-info">
                        <strong>Administrador</strong>
                        <span>Gestão de Utilizadores</span>
                    </div>
                </div>
            </div>
        </header>

        <section class="page-header">
            <h1>Gestão de Utilizadores</h1>
            <p>Acesso exclusivo do administrador</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <div class="crud-header">
                    <h2>Lista de Utilizadores</h2>

                    <a href="utilizador_criar.jsp" class="crud-btn">
                        + Novo Utilizador
                    </a>
                </div>

                <div class="table-wrapper">

                    <table class="crud-table">
                        <thead>
                            <tr>
                                <th>Nome</th>
                                <th>Email</th>
                                <th>Perfil</th>
                                <th>Curso</th>
                                <th>Nº Aluno</th>
                                <th>Estado</th>
                                <th>Criado em</th>
                                <th>Ações</th>
                            </tr>
                        </thead>

                        <tbody>

                        <%
                            boolean temUtilizadores = false;

                            if (rs != null) {
                                while (rs.next()) {
                                    temUtilizadores = true;

                                    int ativo = rs.getInt("ativo");
                                    String estadoTexto = ativo == 1 ? "Ativo" : "Inativo";
                                    String estadoClasse = ativo == 1 ? "estado-ativo" : "estado-inativo";
                        %>

                            <tr>
                                <td><%= rs.getString("nome") %></td>
                                <td><%= rs.getString("email") %></td>
                                <td>
                                    <span class="perfil-badge">
                                        <%= rs.getString("perfil") %>
                                    </span>
                                </td>
                                <td><%= rs.getString("curso") %></td>
                                <td><%= rs.getString("numero_aluno") %></td>
                                <td>
                                    <span class="<%= estadoClasse %>">
                                        <%= estadoTexto %>
                                    </span>
                                </td>
                                <td><%= rs.getString("criado_em") %></td>
                                <td>
                                    <a href="utilizador_editar.jsp?id=<%= rs.getInt("id") %>" class="btn-editar">
                                        Editar
                                    </a>

                                   <a href="utilizador_eliminar.jsp?id=<%= rs.getInt("id") %>" class="btn-eliminar"
                                     onclick="return confirm('Tens a certeza que queres eliminar/inativar este utilizador?');"> Eliminar</a>
                                </td>
                            </tr>

                        <%
                                }
                            }

                            if (!temUtilizadores) {
                        %>

                            <tr>
                                <td colspan="8" class="empty-table-message">
                                    Ainda não existem utilizadores registados.
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