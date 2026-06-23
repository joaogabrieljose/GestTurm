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
    response.sendRedirect("inscricoes.jsp?erro=id_invalido");
    return;
}

int id = Integer.parseInt(idParam);

Connection con = null;

PreparedStatement psInscricao = null;
PreparedStatement psAlunos = null;
PreparedStatement psDisciplinas = null;
PreparedStatement psTurmas = null;

ResultSet rsInscricao = null;
ResultSet rsAlunos = null;
ResultSet rsDisciplinas = null;
ResultSet rsTurmas = null;

int alunoIdAtual = 0;
int disciplinaIdAtual = 0;
int turmaIdAtual = 0;
String estadoAtual = "";

try {
    con = dbConnect();

    psInscricao = con.prepareStatement(
        "SELECT id, aluno_id, disciplina_id, turma_id, estado " +
        "FROM inscricoes " +
        "WHERE id = ? " +
        "LIMIT 1"
    );
    psInscricao.setInt(1, id);
    rsInscricao = dbQuery(con, psInscricao);

    if (rsInscricao.next()) {
        alunoIdAtual = rsInscricao.getInt("aluno_id");
        disciplinaIdAtual = rsInscricao.getInt("disciplina_id");
        turmaIdAtual = rsInscricao.getInt("turma_id");
        estadoAtual = rsInscricao.getString("estado");
    } else {
        response.sendRedirect("inscricoes.jsp?erro=inscricao_nao_encontrada");
        return;
    }

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
    out.print("Erro ao carregar inscrição: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Editar Inscrição - Gesturma</title>
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
            <h1>Editar Inscrição</h1>
            <p>Atualiza o aluno, disciplina, turma ou estado da inscrição.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <form action="inscricao_atualizar.jsp" method="post" class="crud-form">

                    <input type="hidden" name="id" value="<%= id %>">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Aluno</label>
                            <select name="aluno_id" required>

                                <%
                                    if (rsAlunos != null) {
                                        while (rsAlunos.next()) {
                                            int alunoId = rsAlunos.getInt("id");
                                %>

                                    <option value="<%= alunoId %>" <%= alunoId == alunoIdAtual ? "selected" : "" %>>
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

                                <%
                                    if (rsDisciplinas != null) {
                                        while (rsDisciplinas.next()) {
                                            int disciplinaId = rsDisciplinas.getInt("id");
                                %>

                                    <option value="<%= disciplinaId %>" <%= disciplinaId == disciplinaIdAtual ? "selected" : "" %>>
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

                                <%
                                    if (rsTurmas != null) {
                                        while (rsTurmas.next()) {
                                            int turmaId = rsTurmas.getInt("id");
                                %>

                                    <option 
                                        value="<%= turmaId %>"
                                        data-disciplina="<%= rsTurmas.getInt("disciplina_id") %>"
                                        <%= turmaId == turmaIdAtual ? "selected" : "" %>
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
                                <option value="ATIVA" <%= "ATIVA".equals(estadoAtual) ? "selected" : "" %>>
                                    Ativa
                                </option>

                                <option value="CANCELADA" <%= "CANCELADA".equals(estadoAtual) ? "selected" : "" %>>
                                    Cancelada
                                </option>

                                <option value="ALTERADA" <%= "ALTERADA".equals(estadoAtual) ? "selected" : "" %>>
                                    Alterada
                                </option>
                            </select>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="inscricoes.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Atualizar Inscrição
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
    const turmaAtual = "<%= turmaIdAtual %>";

    function filtrarTurmas() {
        const disciplinaId = disciplinaSelect.value;

        Array.from(turmaSelect.options).forEach(function(option) {
            option.style.display = option.dataset.disciplina === disciplinaId ? "block" : "none";
        });

        const selectedOption = turmaSelect.options[turmaSelect.selectedIndex];

        if (selectedOption && selectedOption.dataset.disciplina !== disciplinaId) {
            turmaSelect.value = "";
        }
    }

    disciplinaSelect.addEventListener("change", filtrarTurmas);
    filtrarTurmas();
</script>

<%
    dbClose(rsInscricao, psInscricao, null);
    dbClose(rsAlunos, psAlunos, null);
    dbClose(rsDisciplinas, psDisciplinas, null);
    dbClose(rsTurmas, psTurmas, con);
%>

</body>
</html>