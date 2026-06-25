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

    /*
        Buscar o coordenador autenticado
    */
    ps = con.prepareStatement(
        "SELECT c.id AS coordenador_id, u.nome " +
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
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=coordenador_nao_encontrado");
        return;
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    /*
        Consultar estados das inscrições das disciplinas do coordenador
    */
    ps = con.prepareStatement(
        "SELECT " +
        "i.id, " +
        "i.estado, " +
        "u.nome AS aluno_nome, " +
        "d.nome AS disciplina, " +
        "d.codigo AS codigo_disciplina " +
        "FROM inscricoes i " +
        "INNER JOIN alunos a ON a.id = i.aluno_id " +
        "INNER JOIN utilizadores u ON u.id = a.utilizador_id " +
        "INNER JOIN disciplinas d ON d.id = i.disciplina_id " +
        "WHERE d.coordenador_id = ? " +
        "ORDER BY u.nome, d.nome, i.estado"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar estados das inscrições: " + e.getMessage());
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
    <title>Consultar Estado - Gesturma</title>
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
                <input type="text" placeholder="Consultar estado das inscrições" disabled>
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
            <h1>Consultar Estado</h1>
            <p>
                Consulta e altera o estado das inscrições dos alunos nas tuas disciplinas.
            </p>
        </section>

        <section class="profile-section">

            <div class="profile-card">

                <div class="crud-header">
                    <h2>Estado das Inscrições</h2>

                    <a href="gestao_inscricoes.jsp" class="btn-voltar">
                        Voltar
                    </a>
                </div>

                <div class="table-wrapper">

                    <table class="crud-table">
                        <thead>
                            <tr>
                                <th>Aluno</th>
                                <th>Disciplina</th>
                                <th>Estado</th>
                                <th>Ações</th>
                            </tr>
                        </thead>

                        <tbody>

                        <%
                            boolean temEstados = false;

                            if (rs != null) {
                                while (rs.next()) {
                                    temEstados = true;

                                    String estado = rs.getString("estado");
                                    String estadoClasse = "estado-alterada";

                                    if ("ATIVA".equalsIgnoreCase(estado)) {
                                        estadoClasse = "estado-ativo";
                                    } else if ("CANCELADA".equalsIgnoreCase(estado)) {
                                        estadoClasse = "estado-inativo";
                                    }
                        %>

                            <tr>
                                <td>
                                    <%= rs.getString("aluno_nome") %>
                                </td>

                                <td>
                                    <%= rs.getString("disciplina") %>
                                    (<%= rs.getString("codigo_disciplina") %>)
                                </td>

                                <td>
                                    <span class="<%= estadoClasse %>">
                                        <%= estado %>
                                    </span>
                                </td>

                                <td>
                                    <a href="estado_editar.jsp?id=<%= rs.getInt("id") %>" class="btn-editar">
                                        Editar
                                    </a>

                                    <a 
                                        href="estado_cancelar.jsp?id=<%= rs.getInt("id") %>" 
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

                            if (!temEstados) {
                        %>

                            <tr>
                                <td colspan="4" class="empty-table-message">
                                    Ainda não existem inscrições para consultar.
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