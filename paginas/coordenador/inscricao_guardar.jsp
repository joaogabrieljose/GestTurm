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

request.setCharacterEncoding("UTF-8");

String alunoParam = request.getParameter("aluno_id");
String disciplinaParam = request.getParameter("disciplina_id");
String turmaParam = request.getParameter("turma_id");

if (
    alunoParam == null || alunoParam.trim().isEmpty() ||
    disciplinaParam == null || disciplinaParam.trim().isEmpty() ||
    turmaParam == null || turmaParam.trim().isEmpty()
) {
    response.sendRedirect("inscricao_criar.jsp?erro=campos_obrigatorios");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int alunoId = Integer.parseInt(alunoParam);
int disciplinaId = Integer.parseInt(disciplinaParam);
int turmaId = Integer.parseInt(turmaParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

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

    int coordenadorId = 0;

    if (rs.next()) {
        coordenadorId = rs.getInt("coordenador_id");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (coordenadorId == 0) {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=coordenador_nao_encontrado");
        return;
    }

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM disciplinas " +
        "WHERE id = ? AND coordenador_id = ? AND ativo = 1"
    );

    ps.setInt(1, disciplinaId);
    ps.setInt(2, coordenadorId);
    rs = dbQuery(con, ps);

    int disciplinaPermitida = 0;

    if (rs.next()) {
        disciplinaPermitida = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (disciplinaPermitida == 0) {
        response.sendRedirect("inscricao_criar.jsp?erro=disciplina_nao_permitida");
        return;
    }

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM periodos_inscricao " +
        "WHERE disciplina_id = ? " +
        "AND ativo = 1 " +
        "AND NOW() BETWEEN data_inicio AND data_fim"
    );

    ps.setInt(1, disciplinaId);
    rs = dbQuery(con, ps);

    int periodoAberto = 0;

    if (rs.next()) {
        periodoAberto = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (periodoAberto == 0) {
        response.sendRedirect("inscricao_criar.jsp?erro=periodo_fechado");
        return;
    }

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "WHERE t.id = ? " +
        "AND t.disciplina_id = ? " +
        "AND d.coordenador_id = ? " +
        "AND t.ativo = 1"
    );

    ps.setInt(1, turmaId);
    ps.setInt(2, disciplinaId);
    ps.setInt(3, coordenadorId);
    rs = dbQuery(con, ps);

    int turmaPermitida = 0;

    if (rs.next()) {
        turmaPermitida = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (turmaPermitida == 0) {
        response.sendRedirect("inscricao_criar.jsp?erro=turma_nao_permitida");
        return;
    }

    ps = con.prepareStatement(
        "SELECT " +
        "t.capacidade_maxima, " +
        "COALESCE(ins.total_inscritos, 0) AS total_inscritos " +
        "FROM turmas t " +
        "LEFT JOIN ( " +
        "   SELECT turma_id, COUNT(*) AS total_inscritos " +
        "   FROM inscricoes " +
        "   WHERE estado = 'ATIVA' " +
        "   GROUP BY turma_id " +
        ") ins ON ins.turma_id = t.id " +
        "WHERE t.id = ?"
    );

    ps.setInt(1, turmaId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        int capacidadeMaxima = rs.getInt("capacidade_maxima");
        int totalInscritos = rs.getInt("total_inscritos");

        if (totalInscritos >= capacidadeMaxima) {
            response.sendRedirect("inscricao_criar.jsp?erro=turma_cheia");
            return;
        }
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    ps = con.prepareStatement(
        "INSERT INTO inscricoes " +
        "(aluno_id, disciplina_id, turma_id, estado) " +
        "VALUES (?, ?, ?, 'ATIVA')"
    );

    ps.setInt(1, alunoId);
    ps.setInt(2, disciplinaId);
    ps.setInt(3, turmaId);

    ps.executeUpdate();

    response.sendRedirect("inscricoes.jsp?sucesso=inscricao_criada");
    return;

} catch (SQLIntegrityConstraintViolationException e) {

    response.sendRedirect("inscricao_criar.jsp?erro=aluno_ja_inscrito_nesta_disciplina");
    return;

} catch (Exception e) {

    out.print("<h2>Erro ao guardar inscrição</h2>");
    out.print("<p>" + e.getMessage() + "</p>");
    out.print("<a href='inscricao_criar.jsp'>Voltar</a>");

} finally {
    dbClose(rs, ps, con);
}
%>