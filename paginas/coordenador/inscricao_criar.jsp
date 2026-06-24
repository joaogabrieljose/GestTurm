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

PreparedStatement psCoord = null;
PreparedStatement psAlunos = null;
PreparedStatement psDisciplinas = null;
PreparedStatement psTurmas = null;

ResultSet rsCoord = null;
ResultSet rsAlunos = null;
ResultSet rsDisciplinas = null;
ResultSet rsTurmas = null;

int coordenadorId = 0;
String nomeCoordenador = "";

try {
    con = dbConnect();

    psCoord = con.prepareStatement(
        "SELECT c.id AS coordenador_id, u.nome " +
        "FROM coordenadores c " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE u.id = ? AND u.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    psCoord.setInt(1, userId);
    rsCoord = dbQuery(con, psCoord);

    if (rsCoord.next()) {
        coordenadorId = rsCoord.getInt("coordenador_id");
        nomeCoordenador = rsCoord.getString("nome");
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=coordenador_nao_encontrado");
        return;
    }

    dbClose(rsCoord, psCoord, null);
    rsCoord = null;
    psCoord = null;

    psAlunos = con.prepareStatement(
        "SELECT a.id, u.nome, a.numero_aluno " +
        "FROM alunos a " +
        "INNER JOIN utilizadores u ON u.id = a.utilizador_id " +
        "WHERE u.ativo = 1 " +
        "ORDER BY u.nome"
    );
    rsAlunos = dbQuery(con, psAlunos);

    psDisciplinas = con.prepareStatement(
        "SELECT d.id, d.nome, d.codigo " +
        "FROM disciplinas d " +
        "INNER JOIN periodos_inscricao pi ON pi.disciplina_id = d.id " +
        "WHERE d.coordenador_id = ? " +
        "AND d.ativo = 1 " +
        "AND pi.ativo = 1 " +
        "AND NOW() BETWEEN pi.data_inicio AND pi.data_fim " +
        "ORDER BY d.nome"
    );
    psDisciplinas.setInt(1, coordenadorId);
    rsDisciplinas = dbQuery(con, psDisciplinas);

    psTurmas = con.prepareStatement(
        "SELECT " +
        "t.id, t.disciplina_id, t.nome AS turma, " +
        "d.nome AS disciplina, d.codigo, " +
        "t.capacidade_maxima, " +
        "COALESCE(ins.total_inscritos, 0) AS total_inscritos, " +
        "(t.capacidade_maxima - COALESCE(ins.total_inscritos, 0)) AS vagas " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "LEFT JOIN ( " +
        "   SELECT turma_id, COUNT(*) AS total_inscritos " +
        "   FROM inscricoes " +
        "   WHERE estado = 'ATIVA' " +
        "   GROUP BY turma_id " +
        ") ins ON ins.turma_id = t.id " +
        "WHERE d.coordenador_id = ? " +
        "AND d.ativo = 1 " +
        "AND t.ativo = 1 " +
        "ORDER BY d.nome, t.nome"
    );
    psTurmas.setInt(1, coordenadorId);
    rsTurmas = dbQuery(con, psTurmas);

} catch (Exception e) {
    out.print("Erro ao carregar dados: " + e.getMessage());
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
                <input type="text" placeholder="Nova inscrição" disabled>
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
            <h1>Nova Inscrição</h1>
            <p>Cria uma inscrição para um aluno numa disciplina e turma com período aberto.</p>
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
                            <label>Disciplina com período aberto</label>
                            <select name="disciplina_id" id="disciplinaSelect" required>
                                <option value="">Selecionar disciplina</option>

                                <%
                                    boolean temDisciplinasAbertas = false;

                                    if (rsDisciplinas != null) {
                                        while (rsDisciplinas.next()) {
                                            temDisciplinasAbertas = true;
                                %>

                                    <option value="<%= rsDisciplinas.getInt("id") %>">
                                        <%= rsDisciplinas.getString("nome") %>
                                        (<%= rsDisciplinas.getString("codigo") %>)
                                    </option>

                                <%
                                        }
                                    }
                                %>

                            </select>

                            <%
                                if (!temDisciplinasAbertas) {
                            %>
                                <small>Não existem disciplinas com período de inscrição aberto.</small>
                            <%
                                }
                            %>
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
                                        <%= rsTurmas.getString("turma") %>
                                        -
                                        <%= rsTurmas.getString("disciplina") %>
                                        (<%= rsTurmas.getString("codigo") %>)
                                        |
                                        Vagas: <%= rsTurmas.getInt("vagas") %>
                                    </option>

                                <%
                                        }
                                    }
                                %>

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