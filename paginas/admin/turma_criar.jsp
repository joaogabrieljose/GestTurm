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
ResultSet rsDisc = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT id, nome, codigo " +
        "FROM disciplinas " +
        "WHERE ativo = 1 " +
        "ORDER BY nome"
    );

    rsDisc = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar disciplinas: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Nova Turma - Gesturma</title>
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
            <h1>Nova Turma</h1>
            <p>Preenche os dados para criar uma turma e o respetivo horário.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <form action="turma_guardar.jsp" method="post" class="crud-form">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Disciplina</label>
                            <select name="disciplina_id" required>
                                <option value="">Selecionar disciplina</option>

                                <%
                                    if (rsDisc != null) {
                                        while (rsDisc.next()) {
                                %>

                                    <option value="<%= rsDisc.getInt("id") %>">
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
                            <input type="text" name="nome" placeholder="Ex: Turma ES-A" required>
                        </div>

                        <div class="form-group">
                            <label>Tipo</label>
                            <select name="tipo" required>
                                <option value="">Selecionar tipo</option>
                                <option value="TEORICA">Teórica</option>
                                <option value="PRATICA">Prática</option>
                                <option value="TEORICO_PRATICA">Teórico-Prática</option>
                                <option value="LABORATORIAL">Laboratorial</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label>Capacidade mínima</label>
                            <input type="number" name="capacidade_minima" min="0" required>
                        </div>

                        <div class="form-group">
                            <label>Capacidade máxima</label>
                            <input type="number" name="capacidade_maxima" min="0" required>
                        </div>

                        <div class="form-group">
                            <label>Estado</label>
                            <select name="ativo" required>
                                <option value="1">Ativa</option>
                                <option value="0">Inativa</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label>Dia da semana</label>
                            <select name="dia_semana" required>
                                <option value="">Selecionar dia</option>
                                <option value="SEGUNDA">Segunda</option>
                                <option value="TERCA">Terça</option>
                                <option value="QUARTA">Quarta</option>
                                <option value="QUINTA">Quinta</option>
                                <option value="SEXTA">Sexta</option>
                                <option value="SABADO">Sábado</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label>Hora de início</label>
                            <input type="time" name="hora_inicio" required>
                        </div>

                        <div class="form-group">
                            <label>Hora de fim</label>
                            <input type="time" name="hora_fim" required>
                        </div>

                        <div class="form-group">
                            <label>Sala</label>
                            <input type="text" name="sala" placeholder="Ex: Sala 1.1 / Lab 2" required>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="turmas.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Guardar Turma
                        </button>
                    </div>

                </form>

            </div>
        </section>

    </main>

</div>

<%
    dbClose(rsDisc, ps, con);
%>

</body>
</html>