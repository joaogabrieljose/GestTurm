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

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT c.id AS coordenador_id " +
        "FROM coordenadores c " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE u.id = ? AND u.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        coordenadorId = rs.getInt("coordenador_id");
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=coordenador_nao_encontrado");
        return;
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    ps = con.prepareStatement(
        "SELECT id, nome, codigo " +
        "FROM disciplinas " +
        "WHERE coordenador_id = ? AND ativo = 1 " +
        "ORDER BY nome"
    );

    ps.setInt(1, coordenadorId);
    rs = dbQuery(con, ps);

} catch (Exception e) {
    out.print("Erro ao carregar disciplinas: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Nova Turma - Coordenador</title>
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
            <a href="periodos.jsp">Períodos de Inscrição</a>
            <a href="inscricoes.jsp">Inscrições</a>
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
            <h1>Nova Turma</h1>
            <p>Cria uma turma para uma das tuas disciplinas.</p>
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
                                    if (rs != null) {
                                        while (rs.next()) {
                                %>

                                    <option value="<%= rs.getInt("id") %>">
                                        <%= rs.getString("nome") %> (<%= rs.getString("codigo") %>)
                                    </option>

                                <%
                                        }
                                    }
                                %>

                            </select>
                        </div>

                        <div class="form-group">
                            <label>Nome da turma</label>
                            <input type="text" name="nome" placeholder="Ex: Turma ES-C" required>
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
                            <input type="text" name="sala" required>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="turmas.jsp" class="btn-voltar">Voltar</a>

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
    dbClose(rs, ps, con);
%>

</body>
</html>