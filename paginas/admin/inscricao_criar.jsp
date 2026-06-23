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

PreparedStatement psAlunos = null;
PreparedStatement psDisciplinas = null;
PreparedStatement psTurmas = null;

ResultSet rsAlunos = null;
ResultSet rsDisciplinas = null;
ResultSet rsTurmas = null;

try {
    con = dbConnect();

    psAlunos = con.prepareStatement(
        "SELECT a.id, u.nome, a.numero_aluno " +
        "FROM alunos a " +
        "INNER JOIN utilizadores u ON u.id = a.utilizador_id " +
        "WHERE u.ativo = 1 " +
        "ORDER BY u.nome"
    );
    rsAlunos = dbQuery(con, psAlunos);

    psDisciplinas = con.prepareStatement(
        "SELECT id, nome, codigo " +
        "FROM disciplinas " +
        "WHERE ativo = 1 " +
        "ORDER BY nome"
    );
    rsDisciplinas = dbQuery(con, psDisciplinas);

    psTurmas = con.prepareStatement(
        "SELECT t.id, t.disciplina_id, t.nome AS turma, d.nome AS disciplina, d.codigo " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "WHERE t.ativo = 1 AND d.ativo = 1 " +
        "ORDER BY d.nome, t.nome"
    );
    rsTurmas = dbQuery(con, psTurmas);

} catch (Exception e) {
    out.print("Erro ao carregar dados: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Nova Inscrição - Gesturma</title>
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
            <a href="disciplinas.jsp">Gestão de Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="inscricoes.jsp" class="active">Gestão de Inscrições</a>
        </nav>

        <div class="logout-area">
            <a href="<%= request.getContextPath() %>/paginas/logout.jsp" class="logout-btn">
                Terminar sessão
            </a>
        </div>
    </aside>

    <main class="main-content">

        <section class="page-header">
            <h1>Nova Inscrição</h1>
            <p>Seleciona o aluno, a disciplina e a turma pretendida.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <form action="inscricao_guardar.jsp" method="post" class="crud-form">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Aluno</label>
                            <select name="aluno_id" required>
                                <option value="">Selecionar aluno</option>

                                <%
                                    if (rsAlunos != null) {
                                        while (rsAlunos.next()) {
                                %>

                                    <option value="<%= rsAlunos.getInt("id") %>">
                                        <%= rsAlunos.getString("nome") %> - Nº <%= rsAlunos.getString("numero_aluno") %>
                                    </option>

                                <%
                                        }
                                    }
                                %>

                            </select>
                        </div>

                        <div class="form-group">
                            <label>Disciplina</label>
                            <select name="disciplina_id" id="disciplinaSelect" required>
                                <option value="">Selecionar disciplina</option>

                                <%
                                    if (rsDisciplinas != null) {
                                        while (rsDisciplinas.next()) {
                                %>

                                    <option value="<%= rsDisciplinas.getInt("id") %>">
                                        <%= rsDisciplinas.getString("nome") %> (<%= rsDisciplinas.getString("codigo") %>)
                                    </option>

                                <%
                                        }
                                    }
                                %>

                            </select>
                        </div>

                        <div class="form-group">
                            <label>Turma</label>
                            <select name="turma_id" id="turmaSelect" required>
                                <option value="">Selecionar turma</option>

                                <%
                                    if (rsTurmas != null) {
                                        while (rsTurmas.next()) {
                                %>

                                    <option 
                                        value="<%= rsTurmas.getInt("id") %>"
                                        data-disciplina="<%= rsTurmas.getInt("disciplina_id") %>"
                                    >
                                        <%= rsTurmas.getString("turma") %> - 
                                        <%= rsTurmas.getString("disciplina") %> 
                                        (<%= rsTurmas.getString("codigo") %>)
                                    </option>

                                <%
                                        }
                                    }
                                %>

                            </select>
                        </div>

                        <div class="form-group">
                            <label>Estado</label>
                            <select name="estado" required>
                                <option value="ATIVA">Ativa</option>
                                <option value="CANCELADA">Cancelada</option>
                                <option value="ALTERADA">Alterada</option>
                            </select>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="inscricoes.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Guardar Inscrição
                        </button>
                    </div>

                </form>

            </div>
        </section>

    </main>

</div>

<script>
    const disciplinaSelect = document.getElementById("disciplinaSelect");
    const turmaSelect = document.getElementById("turmaSelect");

    function filtrarTurmas() {
        const disciplinaId = disciplinaSelect.value;

        Array.from(turmaSelect.options).forEach(function(option) {
            if (!option.value) {
                option.style.display = "block";
                return;
            }

            option.style.display = option.dataset.disciplina === disciplinaId ? "block" : "none";
        });

        turmaSelect.value = "";
    }

    disciplinaSelect.addEventListener("change", filtrarTurmas);
    filtrarTurmas();
</script>

<%
    dbClose(rsAlunos, psAlunos, null);
    dbClose(rsDisciplinas, psDisciplinas, null);
    dbClose(rsTurmas, psTurmas, con);
%>

</body>
</html>