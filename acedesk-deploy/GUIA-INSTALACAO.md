# ACE Desk: guia de instalação, passo a passo

Custo: **R$ 0/mês**. Tempo: cerca de 1 hora, na primeira vez.
O que você vai ter no fim: o servidor do ACE Desk no ar em `https://desk.aaccessbr.com`, o PC do estúdio aparecendo lá e o iPhone controlando esse PC pelo app da tela inicial.

---

## Parte 0: GitHub (onde o código do ACE Desk fica guardado)

O código precisa ficar público, porque a licença exige, e o servidor baixa ele de lá.

1. Entre em **github.com** → **Sign up** e crie uma conta grátis (pode usar o ace@aaccessbr.com).
2. No **claude.ai** → **Configurações** → **Conectores**, conecte o **GitHub**.
3. Me avise no chat: eu crio o repositório `ace-desk` na sua conta e envio o código.

---

## Parte 1: criar a conta grátis na Oracle Cloud

1. Abra **oracle.com/br/cloud/free** e clique em **Comece gratuitamente**.
2. Preencha país (Brasil), nome e e-mail, e confirme o e-mail.
3. **Home Region: escolha "Brazil East (Sao Paulo)".** ⚠️ Isso não dá para mudar depois, e o servidor perto de você é o que deixa o acesso rápido.
4. Informe o cartão. É só verificação, e a Oracle pode fazer uma cobrança temporária de cerca de US$ 1, que é estornada. A conta fica no plano **Always Free**, que não cobra nada enquanto você não clicar em "Upgrade".
5. Espere o e-mail "Your account is ready" (de alguns minutos até algumas horas).

## Parte 2: criar o servidor (VM)

1. Entre em **cloud.oracle.com** → menu ☰ (canto superior esquerdo) → **Compute** → **Instances** → **Create instance**.
2. **Name:** `ace-desk`
3. **Image and shape** → **Edit**:
   - **Change image** → **Ubuntu** → **Canonical Ubuntu 24.04** → **Select image**
   - **Change shape** → **Ampere** → **VM.Standard.A1.Flex**, com **2 OCPUs** e **12 GB** de memória → **Select shape**
   - Se aparecer *"Out of capacity"*, use **Specialty and previous generation** → **VM.Standard.E2.1.Micro** (também é grátis).
4. **Networking:** deixe o padrão e confira se está marcado **Assign a public IPv4 address**.
5. **Add SSH keys:** marque **Generate a key pair for me** → clique em **Save private key**. O arquivo vai para Downloads; **guarde bem**.
6. Clique em **Create**. Em 1 ou 2 minutos fica verde (**Running**).
7. Na página da instância, **copie o "Public IP address"**, por exemplo `129.148.x.x`. 📸 Se quiser, me mande um print dessa tela.

## Parte 3: abrir as portas na Oracle

1. Na página da instância → **Primary VNIC** → clique no nome da **Subnet**.
2. Aba **Security** (ou **Security Lists**) → clique em **Default Security List…** → **Add Ingress Rules**.
3. Adicione **uma regra por linha** (Source CIDR sempre `0.0.0.0/0`):

| IP Protocol | Destination Port Range |
|---|---|
| TCP | `80,443` |
| TCP | `21115-21117` |
| UDP | `21116` |

4. Clique em **Add Ingress Rules**.

## Parte 4: apontar o endereço desk.aaccessbr.com

1. Entre no **Squarespace** → **Domains** → **aaccessbr.com** → **DNS** → **DNS Settings** → **Add record**.
2. **Type:** `A` · **Host:** `desk` · **Data/IP:** o IP da Parte 2 → **Save**.
3. Espere de 5 a 30 minutos.

## Parte 5: instalar o ACE Desk no servidor

1. No PC, abra o **PowerShell** (tecla Windows → digite *PowerShell* → Enter).
2. Cole o comando abaixo, trocando o nome do arquivo da chave e o IP:

```powershell
ssh -i "$HOME\Downloads\ssh-key-2026-11-18.key" ubuntu@SEU_IP
```

   - Na pergunta *"Are you sure you want to continue connecting"*, digite `yes`.
   - Se der erro **"UNPROTECTED PRIVATE KEY FILE"**, rode isto uma vez e tente de novo:
     ```powershell
     icacls "$HOME\Downloads\ssh-key-2026-11-18.key" /inheritance:r /grant:r "$($env:USERNAME):R"
     ```
3. Já dentro do servidor (o texto começa com `ubuntu@ace-desk`), cole:

```bash
git clone https://github.com/SEU_USUARIO_GITHUB/ace-desk.git
cd ace-desk/acedesk-deploy
bash instalar-servidor.sh desk.aaccessbr.com
```

4. No fim, ele mostra o **endereço**, o **usuário**, a **senha** e a **chave do servidor**. **Copie tudo** e guarde. A chave vai em cada PC.

## Parte 6: deixar o PC do estúdio pronto para receber acesso

> Na versão 1, os PCs usam o app oficial do RustDesk configurado para o seu servidor. A versão com o nome e o ícone do ACE Desk vem na etapa seguinte.

1. Baixe o RustDesk em **rustdesk.com** → **Download** → Windows (x64) e instale.
2. No RustDesk: **⋮** (ao lado do ID) → **Rede** → **Servidor ID/Relay**:
   - **Servidor de ID:** `desk.aaccessbr.com`
   - **Servidor Relay:** `desk.aaccessbr.com`
   - **Servidor API:** `https://desk.aaccessbr.com`
   - **Chave:** a chave copiada na Parte 5 → **OK**
3. **Segurança** → **Senha** → **Usar senha permanente** → crie uma senha forte. É ela que deixa você entrar sem ninguém aceitar do outro lado.
4. **Geral** → confirme **Iniciar com o Windows / serviço instalado**.
5. Anote o **ID** que aparece na tela inicial.

## Parte 7: o iPhone

1. No iPhone, abra o **Safari** → `https://desk.aaccessbr.com` → entre com o usuário e a senha da Parte 5.
2. Em **Dispositivos**, dê ao PC o nome **PC Estúdio**.
3. Toque em **Conectar (web)** → digite a senha permanente e marque para lembrar.
4. Com a sessão aberta: botão **Compartilhar** do Safari → **Adicionar à Tela de Início** → nome **ACE Desk**.
5. A partir daí, é só tocar no ícone para conectar direto.

**A barra de teclas:** a primeira página é **Atalhos** (Ctrl, Shift, Alt e Win logo no começo, seguidos de Copiar, Colar, Desfazer, Sel. tudo, Salvar, Alt+Tab, Área de trab., Esc, Enter, Del e Ctrl+Alt+Del).
Para **qualquer outra combinação**: toque em **Ctrl** (ou Shift, Alt, Win), que fica com borda vermelha, e depois na tecla. Com **dois toques rápidos** a tecla fica **travada**, toda vermelha, até você tocar de novo. O botão vermelho no canto troca as páginas: **Teclas** (setas, Tab, Home/End…) e **F1–F12**.

---

### Deu problema?
- **O site não abre:** confira o DNS (Parte 4) e as portas 80/443 (Parte 3).
- **O PC aparece offline:** confira a chave e os servidores (Parte 6) e as portas 21115–21117/UDP 21116 (Parte 3).
- **Está lento no 4G:** me avise. Dá para ligar um servidor TURN grátis que ajuda a conexão direta.
