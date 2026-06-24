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
    response.sendRedirect("turmas.jsp?erro=id_invalido");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int turmaId = Integer.parseInt(idParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    /* Buscar coordenador autenticado */
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

    /* Verificar se a turma pertence ao coordenador */
    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "WHERE t.id = ? AND d.coordenador_id = ?"
    );

    ps.setInt(1, turmaId);
    ps.setInt(2, coordenadorId);
    rs = dbQuery(con, ps);

    int turmaPermitida = 0;

    if (rs.next()) {
        turmaPermitida = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (turmaPermitida == 0) {
        response.sendRedirect("turmas.jsp?erro=turma_nao_permitida");
        return;
    }

    /* Inativar turma */
    ps = con.prepareStatement(
        "UPDATE turmas " +
        "SET ativo = 0 " +
        "WHERE id = ?"
    );

    ps.setInt(1, turmaId);
    ps.executeUpdate();

    response.sendRedirect("turmas.jsp?sucesso=turma_inativada");
    return;

} catch (Exception e) {
    out.print("Erro ao eliminar/inativar turma: " + e.getMessage());

} finally {
    dbClose(rs, ps, con);
}
%>