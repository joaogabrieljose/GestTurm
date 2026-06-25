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
          <li><a href="#" class="active">Início</a></li>
          <li><a href="#cursos">Turmas e Vagas</a></li>
          <li><a href="#horarios">Horários</a></li>
          <li><a href="#" class="open-login-modal">Login</a></li>
          <li><a href="#" class="open-register-modal">Inscreva-se</a></li>
        </ul>
      </nav>

    </div>
  </header>

  <main>

    <section class="hero">

      <div class="hero-text">

        <div class="tag">
          <h1>
            Gestão equilibrada de turmas académicas<span>.</span>
          </h1>
        </div>

        <p>
          <strong>O Gesturma é uma plataforma académica</strong> criada para facilitar
          a inscrição dos alunos em turmas no início de cada semestre.
          O sistema permite gerir <strong>disciplinas, turmas, horários, vagas,
          inscrições e períodos de inscrição</strong>, ajudando a evitar que algumas
          turmas fiquem cheias enquanto outras ficam vazias.
        </p>

        <a href="#cursos" class="btn-primary">Ver Turmas</a>

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
            <strong>Vagas e inscrições</strong>
          </div>

          <div class="investment-user">

            <div class="avatar">GT</div>

            <div>
              <h4>Gestão de Turmas</h4>
              <p>Controlo de vagas e balanceamento</p>
            </div>

          </div>

        </div>

      </div>

    </section>

  </main>

  <!-- SECÇÃO TURMAS -->
  <section class="courses-section" id="cursos"><br>

    <div class="section-container">

      <div class="section-title">
        <h2>Turmas, Vagas e Balanceamento</h2>

        <p>
          Nesta área é possível consultar as turmas disponíveis, verificar vagas,
          horários, número de inscrições e perceber se existe equilíbrio na distribuição
          dos alunos entre as turmas.
        </p>
      </div>

      <div class="courses-grid" id="turmasGrid">

        <%
          boolean temTurmas = false;

          if (rsT != null) {
            while (rsT.next()) {
              temTurmas = true;

              int inscritos = rsT.getInt("total_inscritos");
              int capacidadeMinima = rsT.getInt("capacidade_minima");
              int capacidadeMaxima = rsT.getInt("capacidade_maxima");
              int vagasDisponiveis = rsT.getInt("vagas_disponiveis");

              String estadoBalanceamento = "";
              String descricaoBalanceamento = "";

              if (inscritos == 0) {
                  estadoBalanceamento = "Turma vazia";
                  descricaoBalanceamento = "Esta turma ainda não tem alunos inscritos.";
              } else if (inscritos < capacidadeMinima) {
                  estadoBalanceamento = "Poucos alunos";
                  descricaoBalanceamento = "A turma ainda está abaixo da capacidade mínima.";
              } else if (inscritos >= capacidadeMinima && inscritos < capacidadeMaxima) {
                  estadoBalanceamento = "Turma equilibrada";
                  descricaoBalanceamento = "A turma tem alunos suficientes e ainda possui vagas.";
              } else {
                  estadoBalanceamento = "Turma cheia";
                  descricaoBalanceamento = "A turma atingiu a capacidade máxima.";
              }
        %>

          <div class="course-card turma-card">

            <h3>
              <%= rsT.getString("turma") %>
            </h3>

            <p>
              <strong>Disciplina:</strong>
              <%= rsT.getString("disciplina") %>
              (<%= rsT.getString("codigo_disciplina") %>)
              <br>

              <strong>Tipo:</strong>
              <%= rsT.getString("tipo_turma").replace("_", " ") %>
              <br>

              <strong>Horário:</strong>
              <%= rsT.getString("horario") %>
            </p>

            <p>
              <strong>Inscrições:</strong>
              <%= inscritos %> alunos inscritos
              <br>

              <strong>Vagas:</strong>
              <%= vagasDisponiveis %> vagas disponíveis
              <br>

              <strong>Capacidade:</strong>
              mínimo <%= capacidadeMinima %> /
              máximo <%= capacidadeMaxima %>
            </p>

            <strong>
              Balanceamento: <%= estadoBalanceamento %>
            </strong>

            <p>
              <%= descricaoBalanceamento %>
            </p>

          </div>

        <%
            }
          }

          if (!temTurmas) {
        %>

          <div class="course-card">

            <h3>Sem turmas disponíveis</h3>

            <p>
              Ainda não existem turmas registadas na base de dados.
            </p>

            <strong>
              Não existem dados para analisar vagas, inscrições ou balanceamento.
            </strong>

          </div>

        <%
          }
        %>

      </div>

      <div class="pagination-container" id="turmasPagination"></div>

    </div><br><br>

  </section>

  <!-- SECÇÃO HORÁRIOS -->
  <section class="horarios-section" id="horarios">

    <div class="section-container">

      <div class="section-title">
        <h2>saber mais</h2>
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
        <a href="#cursos">Turmas e Vagas</a>
        <a href="#horarios">Horários</a>

      </div>

      <div class="footer-column">

        <h3>Gestão Académica</h3>

        <a href="#cursos">Turmas</a>
        <a href="#">Disciplinas</a>
       <li><a href="#" class="open-register-modal">Inscreva-se</a></li>

      </div>

      <div class="footer-column">

        <h3>Sistema</h3>

        <a href="#" class="open-login-modal">Login</a>
        <a href="#">Inscreva-se</a>
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
            required
          />

        </div>

        <div class="form-group">

          <label for="password">Palavra-passe</label>

          <input 
            type="password" 
            id="password" 
            name="password" 
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

  <!-- SCRIPT DA PAGINAÇÃO DAS TURMAS -->
  <script>
    document.addEventListener("DOMContentLoaded", function () {
      const cards = Array.from(document.querySelectorAll(".turma-card"));
      const pagination = document.getElementById("turmasPagination");

      const turmasPorPagina = 6;
      let paginaAtual = 1;

      const totalPaginas = Math.ceil(cards.length / turmasPorPagina);

      if (!pagination || cards.length === 0 || totalPaginas <= 1) {
        if (pagination) {
          pagination.style.display = "none";
        }

        return;
      }

      function mostrarPagina(pagina) {
        if (pagina < 1) {
          pagina = 1;
        }

        if (pagina > totalPaginas) {
          pagina = totalPaginas;
        }

        paginaAtual = pagina;

        const inicio = (paginaAtual - 1) * turmasPorPagina;
        const fim = inicio + turmasPorPagina;

        cards.forEach(function (card, index) {
          if (index >= inicio && index < fim) {
            card.style.display = "block";
          } else {
            card.style.display = "none";
          }
        });

        desenharBotoes();
      }

      function desenharBotoes() {
        pagination.innerHTML = "";

        const btnAnterior = document.createElement("button");
        btnAnterior.innerHTML = "&lt;&lt;";
        btnAnterior.className = "pagination-btn";
        btnAnterior.disabled = paginaAtual === 1;

        btnAnterior.onclick = function () {
          mostrarPagina(paginaAtual - 1);
          document.getElementById("cursos").scrollIntoView({ behavior: "smooth" });
        };

        pagination.appendChild(btnAnterior);

        for (let i = 1; i <= totalPaginas; i++) {
          const btnNumero = document.createElement("button");
          btnNumero.textContent = i;
          btnNumero.className = "pagination-btn";

          if (i === paginaAtual) {
            btnNumero.classList.add("active");
          }

          btnNumero.onclick = function () {
            mostrarPagina(i);
            document.getElementById("cursos").scrollIntoView({ behavior: "smooth" });
          };

          pagination.appendChild(btnNumero);
        }

        const btnProximo = document.createElement("button");
        btnProximo.innerHTML = "&gt;&gt;";
        btnProximo.className = "pagination-btn";
        btnProximo.disabled = paginaAtual === totalPaginas;

        btnProximo.onclick = function () {
          mostrarPagina(paginaAtual + 1);
          document.getElementById("cursos").scrollIntoView({ behavior: "smooth" });
        };

        pagination.appendChild(btnProximo);
      }

      mostrarPagina(1);
    });
  </script>

  <!-- MODAL DE REGISTO / INSCREVA-SE -->
  <div class="login-modal-overlay" id="registerModal">

    <div class="login-modal-box register-modal-box">

      <button type="button" class="login-modal-close" id="closeRegisterModal">
        &times;
      </button>

      <div class="login-modal-header">
        <h2>Inscreva-se no Gesturma</h2>
        <p>
          Cria a tua conta de aluno para consultar turmas, horários,
          vagas disponíveis e acompanhar as tuas inscrições.
        </p>
      </div>

      <form class="login-form register-form" action="registo_guardar.jsp" method="post">

        <div class="form-group">
          <label for="nome">Nome completo</label>
          <input 
            type="text" 
            id="nome" 
            name="nome" 
            placeholder="Ex: João Cruz"
            required
          />
        </div>

        <div class="form-group">
          <label for="email_registo">Email</label>
          <input 
            type="email" 
            id="email_registo" 
            name="email" 
            placeholder="exemplo@email.com"
            required
          />
        </div>

        <div class="form-group">
          <label for="numero_aluno">N.º de aluno</label>
          <input 
            type="text" 
            id="numero_aluno" 
            name="numero_aluno" 
            placeholder="Ex: 20230253"
            required
          />
        </div>

        <div class="form-group">
          <label for="curso">Curso</label>
          <input 
            type="text" 
            id="curso" 
            name="curso" 
            placeholder="Ex: Engenharia Informática"
            required
          />
        </div>

        <div class="form-group">
          <label for="ano_curricular">Ano curricular</label>
          <select id="ano_curricular" name="ano_curricular" required>
            <option value="">Seleciona o ano</option>
            <option value="1">1.º ano</option>
            <option value="2">2.º ano</option>
            <option value="3">3.º ano</option>
          </select>
        </div>

        <div class="form-group">
          <label for="password_registo">Palavra-passe</label>
          <input 
            type="password" 
            id="password_registo" 
            name="password" 
            placeholder="Define uma palavra-passe"
            required
          />
        </div>

        <div class="form-group">
          <label for="confirmar_password">Confirmar palavra-passe</label>
          <input 
            type="password" 
            id="confirmar_password" 
            name="confirmar_password" 
            placeholder="Repete a palavra-passe"
            required
          />
        </div>

        <button type="submit" class="login-submit">
          Criar Conta
        </button>

      </form>

      <div class="login-modal-footer">
        <p>Depois de criar a conta, poderás iniciar sessão como aluno.</p>
      </div>

    </div>

  </div>

  <script>
  const registerModal = document.getElementById("registerModal");
  const closeRegisterModal = document.getElementById("closeRegisterModal");
  const openRegisterButtons = document.querySelectorAll(".open-register-modal");

  openRegisterButtons.forEach(function (button) {
    button.onclick = function (event) {
      event.preventDefault();
      registerModal.style.display = "flex";
    };
  });

  closeRegisterModal.onclick = function () {
    registerModal.style.display = "none";
  };

  registerModal.onclick = function (event) {
    if (event.target === registerModal) {
      registerModal.style.display = "none";
    }
  };
</script>

</body>
</html>