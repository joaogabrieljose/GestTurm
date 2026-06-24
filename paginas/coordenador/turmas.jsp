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
        "WHERE d.coordenador_id = ? " +
        "ORDER BY d.nome, t.nome"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar turmas: " + e.getMessage());
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
    <title>Gestão de Turmas - Coordenador</title>
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
            <a href="turmas.jsp" class="active">Gestão de Turmas</a>
            <a href="gestao_inscricoes.jsp">Gestão de Inscrições</a>
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
                <input type="text" placeholder="Pesquisar turmas..." disabled>
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
            <h1>Gestão de Turmas</h1>
            <p>Consulta, cria, edita e inativa turmas das tuas disciplinas.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <div class="crud-header">
                    <h2>Turmas das minhas disciplinas</h2>

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
                                        onclick="return confirm('Tens a certeza que queres inativar esta turma?');"
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
                                    Ainda não existem turmas associadas às tuas disciplinas.
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