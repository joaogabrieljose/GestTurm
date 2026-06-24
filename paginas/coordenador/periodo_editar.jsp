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
    response.sendRedirect("periodos.jsp?erro=id_invalido");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int periodoId = Integer.parseInt(idParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String nomeDisciplina = "";
String codigoDisciplina = "";
String dataInicioInput = "";
String dataFimInput = "";
int ativo = 1;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT " +
        "pi.id, pi.ativo, " +
        "DATE_FORMAT(pi.data_inicio, '%Y-%m-%dT%H:%i') AS data_inicio_input, " +
        "DATE_FORMAT(pi.data_fim, '%Y-%m-%dT%H:%i') AS data_fim_input, " +
        "d.nome AS disciplina, d.codigo AS codigo_disciplina " +
        "FROM periodos_inscricao pi " +
        "INNER JOIN disciplinas d ON d.id = pi.disciplina_id " +
        "INNER JOIN coordenadores c ON c.id = d.coordenador_id " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE pi.id = ? " +
        "AND u.id = ? " +
        "AND u.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, periodoId);
    ps.setInt(2, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        ativo = rs.getInt("ativo");
        dataInicioInput = rs.getString("data_inicio_input");
        dataFimInput = rs.getString("data_fim_input");
        nomeDisciplina = rs.getString("disciplina");
        codigoDisciplina = rs.getString("codigo_disciplina");
    } else {
        response.sendRedirect("periodos.jsp?erro=periodo_nao_permitido");
        return;
    }

} catch (Exception e) {
    out.print("Erro ao carregar período: " + e.getMessage());
} finally {
    dbClose(rs, ps, con);
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Editar Período - Gesturma</title>
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
            <h1>Editar Período de Inscrição</h1>
            <p>Atualiza as datas e o estado do período selecionado.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <form action="periodo_atualizar.jsp" method="post" class="crud-form">

                    <input type="hidden" name="id" value="<%= periodoId %>">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Disciplina</label>
                            <input 
                                type="text" 
                                value="<%= nomeDisciplina %> (<%= codigoDisciplina %>)" 
                                disabled
                            >
                        </div>

                        <div class="form-group">
                            <label>Data de início</label>
                            <input 
                                type="datetime-local" 
                                name="data_inicio" 
                                value="<%= dataInicioInput %>" 
                                required
                            >
                        </div>

                        <div class="form-group">
                            <label>Data de fim</label>
                            <input 
                                type="datetime-local" 
                                name="data_fim" 
                                value="<%= dataFimInput %>" 
                                required
                            >
                        </div>

                        <div class="form-group">
                            <label>Estado</label>
                            <select name="ativo" required>
                                <option value="1" <%= ativo == 1 ? "selected" : "" %>>
                                    Ativo
                                </option>

                                <option value="0" <%= ativo == 0 ? "selected" : "" %>>
                                    Inativo
                                </option>
                            </select>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="periodos.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Atualizar Período
                        </button>
                    </div>

                </form>

            </div>
        </section>

    </main>

</div>

</body>
</html>