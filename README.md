# Desengastando 😮‍💨

Controle de gastos pessoal, simples e **offline**, para Android e iOS.

Não tem cadastro, login nem nuvem: tudo fica só no seu celular.

## Baixar e instalar

### Android

1. Na página de [Releases](../../releases/latest), baixe o APK:
   - `Desengastando-0.2.0-arm64.apk`: serve para quase todos os celulares de 2017 para cá.
   - `Desengastando-0.2.0-arm32.apk`: só para aparelhos bem antigos, se o primeiro não instalar.
2. Abra o arquivo baixado. Na primeira vez, o Android pede para permitir
   **"Instalar apps desconhecidos"** para o navegador ou o gerenciador de arquivos. Permita.
3. Toque em **Instalar**.

> O app não está na Play Store, então o Android pode mostrar um aviso do Play Protect.
> Isso é esperado: toque em "Mais detalhes" e depois em "Instalar assim mesmo".

**Para atualizar**, baixe o APK da versão nova e instale por cima. Seus dados continuam lá.

### iOS

Ainda não há versão pronta para instalar. É preciso compilar o app num Mac com
Xcode (veja o [guia de desenvolvimento](CONTRIBUTING.md)).

## Como usar

### Lançar um gasto ou uma receita

Toque em **+** e digite o valor (o campo já abre selecionado). Depois escolha a
categoria e salve. A data já vem como hoje. A categoria define se o lançamento é
despesa ou receita.

- **Editar:** toque no lançamento.
- **Excluir:** arraste o lançamento para a esquerda. Se foi sem querer, toque em **Desfazer** logo em seguida.
- **Trocar de mês:** use as setas no topo da tela.

### Salário, aluguel, assinaturas: lançamentos fixos

Ao lançar algo, escolha **Fixo**. O app repete o lançamento todo mês, no mesmo dia,
e os próximos 12 meses já aparecem na lista marcados como **Previsto**. Assim você
vê como o mês que vem deve fechar.

Os fixos ficam em **Ajustes → Lançamentos fixos** (ou no ícone de repetição no
topo da aba Lançamentos). Lá você pode:

- **Mudar valor ou dia:** vale do próximo lançamento em diante. O que já passou não muda.
- **Pausar:** para de lançar até você reativar.
- **Excluir:** apaga os lançamentos futuros e mantém o histórico.

Se o dia escolhido não existir no mês (dia 31 em fevereiro, por exemplo), o
lançamento cai no último dia do mês.

### Compras parceladas

Ao lançar, escolha **Parcelado**:

1. Escolha em quantas vezes, de 2x a 48x.
2. Informe o **total** da compra **ou** o valor de **cada parcela**.
3. Confira o resumo (por exemplo, "10x de R$ 120,00 · última em agosto de 2027") e salve.

Cada parcela aparece no seu mês como "Parcela 3/10". Se o total não dividir
certinho, os centavos que sobram vão para a primeira parcela.

Para excluir, toque numa parcela e escolha **Só esta** ou **Esta e as próximas**.
A segunda opção é útil, por exemplo, quando você quita a compra antes do fim.

### Resumo do mês

A aba **Resumo** mostra:

- o saldo do mês;
- a comparação com o mês anterior;
- quanto foi para cada categoria;
- a evolução dos últimos 6 meses.

### Orçamentos

Na aba **Orçamentos**, você define um limite mensal para uma categoria de despesa
(por exemplo, "Mercado: R$ 800"). A barra mostra quanto já foi gasto. O app avisa
quando você chega a **80%** do limite e quando passa dele.

### Relatório em PDF

Na aba **Resumo**, toque no ícone de PDF no topo da tela, ou vá em **Ajustes → Exportar
relatório em PDF**. Escolha um **mês** ou um **período** qualquer e toque em **Gerar PDF**.
O relatório mostra:

- receitas, despesas e saldo do período;
- quanto foi para cada categoria;
- todos os lançamentos, com data, categoria e forma de pagamento.

Parcelas e lançamentos previstos vêm identificados no relatório. Depois de gerar o PDF, você
pode salvar no celular, mandar pelo WhatsApp ou por e-mail, ou imprimir.

### Categorias

Em **Ajustes → Categorias** você cria, renomeia e escolhe a cor e o ícone de cada
categoria. Para mudar a ordem, segure e arraste. A categoria que você não usa mais
pode ser **arquivada**: ela sai da lista na hora de lançar, mas o histórico fica intacto.

## Seus dados e o backup

Os dados ficam **somente no seu celular** e nada é enviado para a internet. Mas,
se você desinstalar o app, trocar de celular ou perder o aparelho, os dados vão
junto. Por isso:

- **Faça backup de vez em quando:** use **Ajustes → Exportar backup** e guarde o
  arquivo no Google Drive, mande por e-mail para você mesmo etc.
- **Para restaurar** (num celular novo, por exemplo): use **Ajustes → Restaurar backup**
  e escolha o arquivo. Atenção: restaurar **substitui** tudo o que está no app.
- **Planilha:** **Ajustes → Exportar planilha** gera um CSV com todos os
  lançamentos, que abre no Excel ou no Google Planilhas.

## Perguntas frequentes

**O app é gratuito?**
Sim. É de código aberto ([MIT](LICENSE)), sem anúncios e sem coleta de dados.

**Precisa de internet?**
Não. O app funciona 100% offline.

**Meu fixo não aparece num mês muito distante.**
Os fixos são lançados com até 12 meses de antecedência. Os meses seguintes vão
aparecendo sozinhos com o passar do tempo.

**Encontrei um problema ou tenho uma sugestão.**
Abra uma [issue](../../issues) contando o que aconteceu.

## Desenvolvimento

Quer compilar o app ou contribuir? Veja o [guia de desenvolvimento](CONTRIBUTING.md).

## Licença

O código está sob a licença [MIT](LICENSE). A fonte [Manrope](https://github.com/googlefonts/manrope) está sob a [SIL OFL 1.1](assets/fonts/manrope/OFL.txt).
