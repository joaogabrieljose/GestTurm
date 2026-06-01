<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../database/basedados.h" %>

<%
/* ===================== TURMAS ===================== */
Connection conT = null;
PreparedStatement psT = null;
ResultSet rsT = null;

try {
    conT = dbConnect();

    psT = conT.prepareStatement(
        "SELECT " +
        "d.nome AS disciplina, " +
        "d.codigo AS codigo_disciplina, " +
        "t.nome AS turma, " +
        "t.tipo AS tipo_turma, " +
        "t.capacidade_minima, " +
        "t.capacidade_maxima, " +
        "COALESCE(ins.total_inscritos, 0) AS total_inscritos, " +
        "(t.capacidade_maxima - COALESCE(ins.total_inscritos, 0)) AS vagas_disponiveis, " +
        "COALESCE(h.lista_horarios, 'Horário ainda não definido') AS horario " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "LEFT JOIN ( " +
        "   SELECT turma_id, COUNT(*) AS total_inscritos " +
        "   FROM inscricoes " +
        "   WHERE estado = 'ATIVA' " +
        "   GROUP BY turma_id " +
        ") ins ON ins.turma_id = t.id " +
        "LEFT JOIN ( " +
        "   SELECT turma_id, " +
        "   GROUP_CONCAT(CONCAT(dia_semana, ' ', TIME_FORMAT(hora_inicio, '%H:%i'), ' - ', TIME_FORMAT(hora_fim, '%H:%i'), ' | ', sala) SEPARATOR ' / ') AS lista_horarios " +
        "   FROM horarios " +
        "   GROUP BY turma_id " +
        ") h ON h.turma_id = t.id " +
        "WHERE t.ativo = 1 AND d.ativo = 1 " +
        "ORDER BY d.nome, t.nome"
    );

    rsT = dbQuery(conT, psT);

} catch(Exception e) {
    out.print("Erro ao carregar turmas: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Gesturma - Página Inicial</title>

  <link rel="stylesheet" href="../css/style.css" />
</head>
<body>

  <header>
    <div class="navbar">
      <div class="logo">
        <div class="logo-icon"></div>
        <span>GESTURMA</span>
      </div>

      <nav>
        <ul>
          <li><a href="#" class="active">Inicio</a></li>
          <li><a href="#cursos">Turmas</a></li>
          <li><a href="#horarios">Horarios</a></li>
          <li><a href="#" class="open-login-modal">Login</a></li>
          <li><a href="#">Inscreva-se</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main>
    <section class="hero">

      <div class="hero-text">
        <div class="tag">
          <h1>
            Turmas organizadas de forma simples<span>.</span>
          </h1>
        </div>

        <p>
          <strong>O Gesturma e uma plataforma academica</strong> criada para facilitar
          a inscricao dos alunos em turmas no inicio de cada semestre.
          O sistema permite gerir <strong>disciplinas, turmas, horarios, vagas e periodos de inscricao.</strong>
        </p>

        <a href="#cursos" class="btn-primary">Saber +</a>
      </div>

      <div class="hero-visual">
        <div class="visual-card visual-main">
          <img src="../img/1.png" alt="Alunos organizados por turmas" />
        </div>

        <div class="visual-card visual-top">
          <img src="../img/2.jpg" alt="Horários e inscrições das turmas" />
        </div>

        <div class="investment-card">
          <div class="investment-header">
            <span>Turmas Disponíveis</span>
            <strong>+24 vagas</strong>
          </div>

          <div class="investment-user">
            <div class="avatar">ES</div>
            <div>
              <h4>Eng. Software</h4>
              <p>3 turmas com inscrições abertas</p>
            </div>
          </div>
        </div>
      </div>

    </section>
  </main>

  <section class="courses-section" id="cursos"></section>

  <!-- SECÇÃO TURMAS -->
  <section class="courses-section" id="cursos">
    <div class="section-container">

      <div class="courses-grid">

        <%
          boolean temTurmas = false;

          if (rsT != null) {
            while (rsT.next()) {
              temTurmas = true;
        %>

          <div class="course-card">
            <h3><%= rsT.getString("disciplina") %></h3>

            <p>
              <strong>Turma:</strong> <%= rsT.getString("turma") %><br>
              <strong>Código:</strong> <%= rsT.getString("codigo_disciplina") %><br>
              <strong>Tipo:</strong> <%= rsT.getString("tipo_turma").replace("_", " ") %><br>
              <strong>Horário:</strong> <%= rsT.getString("horario") %>
            </p>

            <strong>
              <%= rsT.getInt("vagas_disponiveis") %> vagas disponíveis
            </strong>

            <p>
              Inscritos: <%= rsT.getInt("total_inscritos") %> /
              Capacidade máxima: <%= rsT.getInt("capacidade_maxima") %>
            </p>
          </div>

        <%
            }
          }

          if (!temTurmas) {
        %>

          <div class="course-card">
            <h3>Sem turmas disponíveis</h3>
            <p>Ainda não existem turmas registadas na base de dados.</p>
            <strong>0 vagas disponíveis</strong>
          </div>

        <%
          }
        %>

      </div>
    </div>
  </section>

  <!-- SECÇÃO HORÁRIOS -->
  <section class="horarios-section" id="horarios">
    <div class="section-container">

      <div class="section-title">
        <h2>Horários em números</h2>
      </div>

      <div class="horarios-grid">

        <div class="horario-card">
          <h3>Turmas disponíveis</h3>
          <div class="horario-info">
            <strong>12</strong>
          </div>
          <p>Turmas abertas para inscrição no semestre.</p>
        </div>

        <div class="horario-card">
          <h3>Horários publicados</h3>
          <div class="horario-info">
            <strong>18</strong>
          </div>
          <p>Horários disponíveis para consulta pelos alunos.</p>
        </div>

        <div class="horario-card">
          <h3>Disciplinas</h3>
          <div class="horario-info">
            <strong>7</strong>
          </div>
          <p>Disciplinas com turmas associadas.</p>
        </div>

        <div class="horario-card">
          <h3>Vagas abertas</h3>
          <div class="horario-info">
            <strong>24</strong>
          </div>
          <p>Vagas disponíveis para inscrição.</p>
        </div>

        <div class="horario-card">
          <h3>Turmas de manhã</h3>
          <div class="horario-info">
            <strong>5</strong>
          </div>
          <p>Turmas com horário no período da manhã.</p>
        </div>

        <div class="horario-card">
          <h3>Turmas de tarde</h3>
          <div class="horario-info">
            <strong>7</strong>
          </div>
          <p>Turmas com horário no período da tarde.</p>
        </div>

        <div class="horario-card">
          <h3>Salas disponíveis</h3>
          <div class="horario-info">
            <strong>9</strong>
          </div>
          <p>Salas associadas aos horários das turmas.</p>
        </div>

      </div>
    </div>
  </section>

  <!-- RODAPÉ -->
  <footer class="footer">
    <div class="footer-container">

      <div class="footer-about">
        <div class="footer-logo">
          <div class="logo-icon"></div>
          <span>GESTURMA</span>
        </div>

        <p>
          O Gesturma é uma plataforma académica criada para facilitar
          a gestão de turmas, horários, inscrições e balanceamento de alunos.
        </p>
      </div>

      <div class="footer-column">
        <h3>Plataforma</h3>
        <a href="#">Início</a>
        <a href="#cursos">Nossos Cursos</a>
        <a href="#horarios">Horários</a>
      </div>

      <div class="footer-column">
        <h3>Gestão Académica</h3>
        <a href="#">Disciplinas</a>
        <a href="#">Turmas</a>
        <a href="#">Inscrições</a>
      </div>

      <div class="footer-column">
        <h3>Sistema</h3>
        <a href="#" class="open-login-modal">Login</a>
        <a href="#">Inscreva-se</a>
        <a href="#">Administrador</a>
      </div>

    </div>
  </footer>

  <!-- MODAL DE LOGIN -->
  <div class="login-modal-overlay" id="loginModal">
    <div class="login-modal-box">

      <button type="button" class="login-modal-close" id="closeLoginModal">
        &times;
      </button>

      <div class="login-modal-header">
        <h2>Entrar no Gesturma</h2>
        <p>Acede à tua conta para gerir ou consultar turmas.</p>
      </div>

      <form class="login-form" action="login_process.jsp" method="post">

        <div class="form-group">
          <label for="email">Email</label>
          <input 
            type="email" 
            id="email" 
            name="email" 
            placeholder="exemplo@gesturma.pt" 
            required
          />
        </div>

        <div class="form-group">
          <label for="password">Palavra-passe</label>
          <input 
            type="password" 
            id="password" 
            name="password" 
            placeholder="Digite a sua palavra-passe" 
            required
          />
        </div>

        <button type="submit" class="login-submit">
          Entrar
        </button>

      </form>

      <div class="login-modal-footer">
        <p>Perfis disponíveis: Administrador, Coordenador e Aluno.</p>
      </div>

    </div>
  </div>

  <!-- SCRIPT DO MODAL DE LOGIN -->
  <script>
    const loginModal = document.getElementById("loginModal");
    const closeLoginModal = document.getElementById("closeLoginModal");
    const openLoginButtons = document.querySelectorAll(".open-login-modal");

    openLoginButtons.forEach(function (button) {
      button.onclick = function (event) {
        event.preventDefault();
        loginModal.style.display = "flex";
      };
    });

    closeLoginModal.onclick = function () {
      loginModal.style.display = "none";
    };

    loginModal.onclick = function (event) {
      if (event.target === loginModal) {
        loginModal.style.display = "none";
      }
    };

    document.onkeydown = function (event) {
      if (event.key === "Escape") {
        loginModal.style.display = "none";
      }
    };
  </script>

</body>
</html>