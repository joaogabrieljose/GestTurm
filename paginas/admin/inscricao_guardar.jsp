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

request.setCharacterEncoding("UTF-8");

String alunoParam = request.getParameter("aluno_id");
String disciplinaParam = request.getParameter("disciplina_id");
String turmaParam = request.getParameter("turma_id");
String estado = request.getParameter("estado");

if (
    alunoParam == null || alunoParam.trim().isEmpty() ||
    disciplinaParam == null || disciplinaParam.trim().isEmpty() ||
    turmaParam == null || turmaParam.trim().isEmpty() ||
    estado == null || estado.trim().isEmpty()
) {
    response.sendRedirect("inscricao_criar.jsp?erro=campos_obrigatorios");
    return;
}

int alunoId = Integer.parseInt(alunoParam);
int disciplinaId = Integer.parseInt(disciplinaParam);
int turmaId = Integer.parseInt(turmaParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM turmas " +
        "WHERE id = ? AND disciplina_id = ? AND ativo = 1"
    );
    ps.setInt(1, turmaId);
    ps.setInt(2, disciplinaId);
    rs = dbQuery(con, ps);

    int turmaValida = 0;

    if (rs.next()) {
        turmaValida = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (turmaValida == 0) {
        response.sendRedirect("inscricao_criar.jsp?erro=turma_nao_pertence_disciplina");
        return;
    }

    if ("ATIVA".equalsIgnoreCase(estado)) {
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
    }

    ps = con.prepareStatement(
        "INSERT INTO inscricoes " +
        "(aluno_id, disciplina_id, turma_id, estado) " +
        "VALUES (?, ?, ?, ?)"
    );

    ps.setInt(1, alunoId);
    ps.setInt(2, disciplinaId);
    ps.setInt(3, turmaId);
    ps.setString(4, estado.trim());

    ps.executeUpdate();

    response.sendRedirect("inscricoes.jsp?sucesso=inscricao_criada");
    return;

} catch (SQLIntegrityConstraintViolationException e) {
    response.sendRedirect("inscricao_criar.jsp?erro=aluno_ja_inscrito_nesta_disciplina");
    return;

} catch (Exception e) {
    out.print("Erro ao guardar inscrição: " + e.getMessage());

} finally {
    dbClose(rs, ps, con);
}
%>