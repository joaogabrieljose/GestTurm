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

String idParam = request.getParameter("id");

if (idParam == null || idParam.trim().isEmpty()) {
    response.sendRedirect("inscricoes.jsp?erro=id_invalido");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int inscricaoId = Integer.parseInt(idParam);

Connection con = null;

PreparedStatement psInscricao = null;
PreparedStatement psTurmas = null;

ResultSet rsInscricao = null;
ResultSet rsTurmas = null;

int disciplinaId = 0;
int turmaIdAtual = 0;

String alunoNome = "";
String numeroAluno = "";
String disciplinaNome = "";
String disciplinaCodigo = "";
String estadoAtual = "";

try {
    con = dbConnect();

    psInscricao = con.prepareStatement(
        "SELECT " +
        "i.id, i.disciplina_id, i.turma_id, i.estado, " +
        "u.nome AS aluno_nome, " +
        "a.numero_aluno, " +
        "d.nome AS disciplina, " +
        "d.codigo AS codigo_disciplina " +
        "FROM inscricoes i " +
        "INNER JOIN alunos a ON a.id = i.aluno_id " +
        "INNER JOIN utilizadores u ON u.id = a.utilizador_id " +
        "INNER JOIN disciplinas d ON d.id = i.disciplina_id " +
        "INNER JOIN coordenadores c ON c.id = d.coordenador_id " +
        "INNER JOIN utilizadores uc ON uc.id = c.utilizador_id " +
        "WHERE i.id = ? " +
        "AND uc.id = ? " +
        "AND uc.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    psInscricao.setInt(1, inscricaoId);
    psInscricao.setInt(2, userId);
    rsInscricao = dbQuery(con, psInscricao);

    if (rsInscricao.next()) {
        disciplinaId = rsInscricao.getInt("disciplina_id");
        turmaIdAtual = rsInscricao.getInt("turma_id");
        estadoAtual = rsInscricao.getString("estado");

        alunoNome = rsInscricao.getString("aluno_nome");
        numeroAluno = rsInscricao.getString("numero_aluno");
        disciplinaNome = rsInscricao.getString("disciplina");
        disciplinaCodigo = rsInscricao.getString("codigo_disciplina");
    } else {
        response.sendRedirect("inscricoes.jsp?erro=inscricao_nao_permitida");
        return;
    }

    psTurmas = con.prepareStatement(
        "SELECT " +
        "t.id, t.nome, t.tipo, t.capacidade_maxima, " +
        "COALESCE(ins.total_inscritos, 0) AS total_inscritos, " +
        "(t.capacidade_maxima - COALESCE(ins.total_inscritos, 0)) AS vagas " +
        "FROM turmas t " +
        "LEFT JOIN ( " +
        "   SELECT turma_id, COUNT(*) AS total_inscritos " +
        "   FROM inscricoes " +
        "   WHERE estado = 'ATIVA' AND id <> ? " +
        "   GROUP BY turma_id " +
        ") ins ON ins.turma_id = t.id " +
        "WHERE t.disciplina_id = ? " +
        "AND t.ativo = 1 " +
        "ORDER BY t.nome"
    );

    psTurmas.setInt(1, inscricaoId);
    psTurmas.setInt(2, disciplinaId);
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

        <section class="page-header">
            <h1>Editar Inscrição</h1>
            <p>Altera a turma ou o estado da inscrição selecionada.</p>
        </section>

        <section class="profile-section">

            <div class="profile-card">

                <form action="inscricao_atualizar.jsp" method="post" class="crud-form">

                    <input type="hidden" name="id" value="<%= inscricaoId %>">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Aluno</label>
                            <input type="text" value="<%= alunoNome %> - Nº <%= numeroAluno %>" disabled>
                        </div>

                        <div class="form-group">
                            <label>Disciplina</label>
                            <input type="text" value="<%= disciplinaNome %> (<%= disciplinaCodigo %>)" disabled>
                        </div>

                        <div class="form-group">
                            <label>Turma</label>
                            <select name="turma_id" required>

                                <%
                                    if (rsTurmas != null) {
                                        while (rsTurmas.next()) {
                                            int turmaId = rsTurmas.getInt("id");
                                %>

                                    <option value="<%= turmaId %>" <%= turmaId == turmaIdAtual ? "selected" : "" %>>
                                        <%= rsTurmas.getString("nome") %>
                                        -
                                        <%= rsTurmas.getString("tipo").replace("_", " ") %>
                                        |
                                        Vagas: <%= rsTurmas.getInt("vagas") %>
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

<%
    dbClose(rsInscricao, psInscricao, null);
    dbClose(rsTurmas, psTurmas, con);
%>

</body>
</html>