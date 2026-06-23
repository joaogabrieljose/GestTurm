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
    response.sendRedirect("turmas.jsp?erro=id_invalido");
    return;
}

int id = Integer.parseInt(idParam);

Connection con = null;
PreparedStatement psTurma = null;
PreparedStatement psDisc = null;
ResultSet rsTurma = null;
ResultSet rsDisc = null;

int disciplinaId = 0;
int horarioId = 0;
String nome = "";
String tipo = "";
int capacidadeMinima = 0;
int capacidadeMaxima = 0;
int ativo = 1;

String diaSemana = "";
String horaInicio = "";
String horaFim = "";
String sala = "";

try {
    con = dbConnect();

    psTurma = con.prepareStatement(
        "SELECT " +
        "t.id, t.disciplina_id, t.nome, t.tipo, t.capacidade_minima, t.capacidade_maxima, t.ativo, " +
        "COALESCE(h.id, 0) AS horario_id, " +
        "COALESCE(h.dia_semana, '') AS dia_semana, " +
        "COALESCE(TIME_FORMAT(h.hora_inicio, '%H:%i'), '') AS hora_inicio, " +
        "COALESCE(TIME_FORMAT(h.hora_fim, '%H:%i'), '') AS hora_fim, " +
        "COALESCE(h.sala, '') AS sala " +
        "FROM turmas t " +
        "LEFT JOIN horarios h ON h.turma_id = t.id " +
        "WHERE t.id = ? " +
        "ORDER BY h.id ASC " +
        "LIMIT 1"
    );

    psTurma.setInt(1, id);
    rsTurma = dbQuery(con, psTurma);

    if (rsTurma.next()) {
        disciplinaId = rsTurma.getInt("disciplina_id");
        nome = rsTurma.getString("nome");
        tipo = rsTurma.getString("tipo");
        capacidadeMinima = rsTurma.getInt("capacidade_minima");
        capacidadeMaxima = rsTurma.getInt("capacidade_maxima");
        ativo = rsTurma.getInt("ativo");

        horarioId = rsTurma.getInt("horario_id");
        diaSemana = rsTurma.getString("dia_semana");
        horaInicio = rsTurma.getString("hora_inicio");
        horaFim = rsTurma.getString("hora_fim");
        sala = rsTurma.getString("sala");
    } else {
        response.sendRedirect("turmas.jsp?erro=turma_nao_encontrada");
        return;
    }

    psDisc = con.prepareStatement(
        "SELECT id, nome, codigo " +
        "FROM disciplinas " +
        "WHERE ativo = 1 " +
        "ORDER BY nome"
    );

    rsDisc = dbQuery(con, psDisc);

} catch (Exception e) {
    out.print("Erro ao carregar turma: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Editar Turma - Gesturma</title>
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
            <a href="turmas.jsp" class="active">Gestão de Turmas</a>
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
            <h1>Editar Turma</h1>
            <p>Atualiza os dados da turma e do respetivo horário.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <form action="turma_atualizar.jsp" method="post" class="crud-form">

                    <input type="hidden" name="id" value="<%= id %>">
                    <input type="hidden" name="horario_id" value="<%= horarioId %>">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Disciplina</label>
                            <select name="disciplina_id" required>

                                <%
                                    if (rsDisc != null) {
                                        while (rsDisc.next()) {
                                            int discIdAtual = rsDisc.getInt("id");
                                %>

                                    <option 
                                        value="<%= discIdAtual %>"
                                        <%= discIdAtual == disciplinaId ? "selected" : "" %>
                                    >
                                        <%= rsDisc.getString("nome") %> (<%= rsDisc.getString("codigo") %>)
                                    </option>

                                <%
                                        }
                                    }
                                %>

                            </select>
                        </div>

                        <div class="form-group">
                            <label>Nome da turma</label>
                            <input type="text" name="nome" value="<%= nome %>" required>
                        </div>

                        <div class="form-group">
                            <label>Tipo</label>
                            <select name="tipo" required>
                                <option value="TEORICA" <%= "TEORICA".equals(tipo) ? "selected" : "" %>>
                                    Teórica
                                </option>

                                <option value="PRATICA" <%= "PRATICA".equals(tipo) ? "selected" : "" %>>
                                    Prática
                                </option>

                                <option value="TEORICO_PRATICA" <%= "TEORICO_PRATICA".equals(tipo) ? "selected" : "" %>>
                                    Teórico-Prática
                                </option>

                                <option value="LABORATORIAL" <%= "LABORATORIAL".equals(tipo) ? "selected" : "" %>>
                                    Laboratorial
                                </option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label>Capacidade mínima</label>
                            <input type="number" name="capacidade_minima" min="0" value="<%= capacidadeMinima %>" required>
                        </div>

                        <div class="form-group">
                            <label>Capacidade máxima</label>
                            <input type="number" name="capacidade_maxima" min="0" value="<%= capacidadeMaxima %>" required>
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

                        <div class="form-group">
                            <label>Dia da semana</label>
                            <select name="dia_semana" required>
                                <option value="SEGUNDA" <%= "SEGUNDA".equals(diaSemana) ? "selected" : "" %>>Segunda</option>
                                <option value="TERCA" <%= "TERCA".equals(diaSemana) ? "selected" : "" %>>Terça</option>
                                <option value="QUARTA" <%= "QUARTA".equals(diaSemana) ? "selected" : "" %>>Quarta</option>
                                <option value="QUINTA" <%= "QUINTA".equals(diaSemana) ? "selected" : "" %>>Quinta</option>
                                <option value="SEXTA" <%= "SEXTA".equals(diaSemana) ? "selected" : "" %>>Sexta</option>
                                <option value="SABADO" <%= "SABADO".equals(diaSemana) ? "selected" : "" %>>Sábado</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label>Hora de início</label>
                            <input type="time" name="hora_inicio" value="<%= horaInicio %>" required>
                        </div>

                        <div class="form-group">
                            <label>Hora de fim</label>
                            <input type="time" name="hora_fim" value="<%= horaFim %>" required>
                        </div>

                        <div class="form-group">
                            <label>Sala</label>
                            <input type="text" name="sala" value="<%= sala %>" required>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="turmas.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Atualizar Turma
                        </button>
                    </div>

                </form>

            </div>
        </section>

    </main>

</div>

<%
    dbClose(rsTurma, psTurma, null);
    dbClose(rsDisc, psDisc, con);
%>

</body>
</html>