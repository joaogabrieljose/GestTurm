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
        "SELECT d.id, d.nome, d.codigo " +
        "FROM disciplinas d " +
        "LEFT JOIN periodos_inscricao pi ON pi.disciplina_id = d.id " +
        "WHERE d.coordenador_id = ? " +
        "AND d.ativo = 1 " +
        "AND pi.id IS NULL " +
        "ORDER BY d.nome"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar disciplinas: " + e.getMessage());
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
    <title>Novo Período - Gesturma</title>
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
                <input type="text" placeholder="Novo período de inscrição" disabled>
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
            <h1>Novo Período de Inscrição</h1>
            <p>Escolhe a disciplina e define a data de início e fim das inscrições.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <form action="periodo_guardar.jsp" method="post" class="crud-form">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Disciplina</label>
                            <select name="disciplina_id" required>
                                <option value="">Selecionar disciplina</option>

                                <%
                                    boolean temDisciplinas = false;

                                    if (rs != null) {
                                        while (rs.next()) {
                                            temDisciplinas = true;
                                %>

                                    <option value="<%= rs.getInt("id") %>">
                                        <%= rs.getString("nome") %> (<%= rs.getString("codigo") %>)
                                    </option>

                                <%
                                        }
                                    }
                                %>

                            </select>

                            <%
                                if (!temDisciplinas) {
                            %>
                                <small>
                                    Todas as tuas disciplinas já têm período criado.
                                </small>
                            <%
                                }
                            %>
                        </div>

                        <div class="form-group">
                            <label>Data de início</label>
                            <input type="datetime-local" name="data_inicio" required>
                        </div>

                        <div class="form-group">
                            <label>Data de fim</label>
                            <input type="datetime-local" name="data_fim" required>
                        </div>

                        <div class="form-group">
                            <label>Estado</label>
                            <select name="ativo" required>
                                <option value="1">Ativo</option>
                                <option value="0">Inativo</option>
                            </select>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="periodos.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Guardar Período
                        </button>
                    </div>

                </form>

            </div>
        </section>

    </main>

</div>

<%
    dbClose(rs, ps, con);
%>

</body>
</html>