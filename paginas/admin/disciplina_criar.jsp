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
ResultSet rsCoord = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT c.id, u.nome, c.curso " +
        "FROM coordenadores c " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE u.ativo = 1 " +
        "ORDER BY u.nome"
    );

    rsCoord = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar coordenadores: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Nova Disciplina - Gesturma</title>
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
            <a href="utilizadores.jsp">Utilizadores</a>
            <a href="disciplinas.jsp" class="active">Gestão de Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="inscricoes.jsp">Gestão de Inscrições</a>
        </nav>

        <div class="logout-area">
            <a href="<%= request.getContextPath() %>/paginas/logout.jsp" class="logout-btn">
                Terminar sessão
            </a>
        </div>
    </aside>

    <main class="main-content">

        <section class="page-header">
            <h1>Nova Disciplina</h1>
            <p>Preenche os dados para criar uma nova disciplina.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <form action="disciplina_guardar.jsp" method="post" class="crud-form">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Nome da disciplina</label>
                            <input type="text" name="nome" required>
                        </div>

                        <div class="form-group">
                            <label>Código</label>
                            <input type="text" name="codigo" placeholder="Ex: ES, BD, SO" required>
                        </div>

                        <div class="form-group">
                            <label>Coordenador</label>
                            <select name="coordenador_id" required>
                                <option value="">Selecionar coordenador</option>

                                <%
                                    if (rsCoord != null) {
                                        while (rsCoord.next()) {
                                %>

                                    <option value="<%= rsCoord.getInt("id") %>">
                                        <%= rsCoord.getString("nome") %> - <%= rsCoord.getString("curso") %>
                                    </option>

                                <%
                                        }
                                    }
                                %>

                            </select>
                        </div>

                        <div class="form-group">
                            <label>Semestre</label>
                            <select name="semestre" required>
                                <option value="">Selecionar semestre</option>
                                <option value="1">1º Semestre</option>
                                <option value="2">2º Semestre</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label>Ano letivo</label>
                            <input type="text" name="ano_letivo" placeholder="Ex: 2025/2026" required>
                        </div>

                        <div class="form-group">
                            <label>Número de alunos inscritos</label>
                            <input type="number" name="numero_alunos_inscritos" min="0" value="0" required>
                        </div>

                        <div class="form-group">
                            <label>Estado</label>
                            <select name="ativo" required>
                                <option value="1">Ativa</option>
                                <option value="0">Inativa</option>
                            </select>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="disciplinas.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Guardar Disciplina
                        </button>
                    </div>

                </form>

            </div>
        </section>

    </main>

</div>

<%
    dbClose(rsCoord, ps, con);
%>

</body>
</html>