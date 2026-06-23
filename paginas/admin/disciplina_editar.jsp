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

String idParam = request.getParameter("id");

if (idParam == null || idParam.trim().isEmpty()) {
    response.sendRedirect("disciplinas.jsp?erro=id_invalido");
    return;
}

int id = Integer.parseInt(idParam);

Connection con = null;
PreparedStatement psDisciplina = null;
PreparedStatement psCoord = null;
ResultSet rsDisciplina = null;
ResultSet rsCoord = null;

String nome = "";
String codigo = "";
int coordenadorId = 0;
int semestre = 1;
String anoLetivo = "";
int numeroAlunos = 0;
int ativo = 1;

try {
    con = dbConnect();

    psDisciplina = con.prepareStatement(
        "SELECT id, coordenador_id, nome, codigo, semestre, ano_letivo, numero_alunos_inscritos, ativo " +
        "FROM disciplinas " +
        "WHERE id = ? " +
        "LIMIT 1"
    );

    psDisciplina.setInt(1, id);
    rsDisciplina = dbQuery(con, psDisciplina);

    if (rsDisciplina.next()) {
        coordenadorId = rsDisciplina.getInt("coordenador_id");
        nome = rsDisciplina.getString("nome");
        codigo = rsDisciplina.getString("codigo");
        semestre = rsDisciplina.getInt("semestre");
        anoLetivo = rsDisciplina.getString("ano_letivo");
        numeroAlunos = rsDisciplina.getInt("numero_alunos_inscritos");
        ativo = rsDisciplina.getInt("ativo");
    } else {
        response.sendRedirect("disciplinas.jsp?erro=disciplina_nao_encontrada");
        return;
    }

    psCoord = con.prepareStatement(
        "SELECT c.id, u.nome, c.curso " +
        "FROM coordenadores c " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE u.ativo = 1 " +
        "ORDER BY u.nome"
    );

    rsCoord = dbQuery(con, psCoord);

} catch (Exception e) {
    out.print("Erro ao carregar disciplina: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Editar Disciplina - Gesturma</title>
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
            <h1>Editar Disciplina</h1>
            <p>Atualiza os dados da disciplina selecionada.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <form action="disciplina_atualizar.jsp" method="post" class="crud-form">

                    <input type="hidden" name="id" value="<%= id %>">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Nome da disciplina</label>
                            <input type="text" name="nome" value="<%= nome %>" required>
                        </div>

                        <div class="form-group">
                            <label>Código</label>
                            <input type="text" name="codigo" value="<%= codigo %>" required>
                        </div>

                        <div class="form-group">
                            <label>Coordenador</label>
                            <select name="coordenador_id" required>

                                <%
                                    if (rsCoord != null) {
                                        while (rsCoord.next()) {
                                            int coordIdAtual = rsCoord.getInt("id");
                                %>

                                    <option 
                                        value="<%= coordIdAtual %>"
                                        <%= coordIdAtual == coordenadorId ? "selected" : "" %>
                                    >
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
                                <option value="1" <%= semestre == 1 ? "selected" : "" %>>
                                    1º Semestre
                                </option>
                                <option value="2" <%= semestre == 2 ? "selected" : "" %>>
                                    2º Semestre
                                </option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label>Ano letivo</label>
                            <input type="text" name="ano_letivo" value="<%= anoLetivo %>" required>
                        </div>

                        <div class="form-group">
                            <label>Número de alunos inscritos</label>
                            <input type="number" name="numero_alunos_inscritos" min="0" value="<%= numeroAlunos %>" required>
                        </div>

                        <div class="form-group">
                            <label>Estado</label>
                            <select name="ativo" required>
                                <option value="1" <%= ativo == 1 ? "selected" : "" %>>
                                    Ativa
                                </option>
                                <option value="0" <%= ativo == 0 ? "selected" : "" %>>
                                    Inativa
                                </option>
                            </select>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="disciplinas.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Atualizar Disciplina
                        </button>
                    </div>

                </form>

            </div>
        </section>

    </main>

</div>

<%
    dbClose(rsDisciplina, psDisciplina, null);
    dbClose(rsCoord, psCoord, con);
%>

</body>
</html>