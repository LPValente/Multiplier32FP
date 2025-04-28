## Multiplier32FP

O presente trabalho visa implementar um multiplicador em ponto flutuante no padrão [IEEE 754](#ieee-754) de 32 bits em SystemVerilog e executar as sínteses física e lógica para extrair informações de área, potência e timing.

Para executar o presente trabalho foi desenvolvido um script baseado no script "run_first" fornecido pelo professor.
O script desenvolvido permite a automação de vários processos do desenvolvimento do trabalho, auxiliando em tarefas repetitivas.

A [organização das pastas](#organização-das-pastas) foi definida seguindo o padrão determinado, adicionando pequenas mudanças por questão de organização.


Para executar o script basta rodar o comando "./run" no terminal.

##### !!!! A primeira vez que o script for executado, as bibliotecas utilizadas na execução dos programas serão adicionadas ao arquivo "techDir.txt". Por conta disso, a primeira execução pode demorar. Caso as bibliotecas não sejam encontradas o script será encerrado

Após as bibliotecas serem encontradas alguns comandos devem ser enviados pelo terminal

O primeiro dado solicitado será a frequência de operação que será utilizada na simulação ou nas sínteses pelo Genus e Innovus. Por padrão a frequência selecionada é de 10 Mhz, então, caso deseje rodar com 10 Mhz, basta apertar a tecla "ENTER".

Após definir a frequência, o script solicitará qual programa será executado, sendo as opções:

- [Xcelium](#xcelium) (xrun): utilizado para simulação do RTL e dos netlists gerados;
- [Genus](#genus): utilizado para síntese lógica;
- [Innovus](#innovus): utilizado para síntese física.

###### Por padrão o software é o Xcelium, então caso a tecla "ENTER" seja pressionada, o software selecionado será o Xcelium



#### Xcelium
<a name="xcelium"></a>

Com o script desenvolvido, o passo-a-passo foi elaborado para permitir que se escolha entre algumas opções de simulação pelo software Xcelium. Podemos destacar as seguintes opções:

- Escolher o vetor de teste entre o original com 30 vetores com o resultado e o completom com 100 vetores;
- Rodar todas as simulações para gerar os arquivos VCD;
- Rodar com o tempo total (dinâmico e estático) ou apenas o tempo de atividade;
- Qual arquivo rodar (RTL, netlist lógico, netlist lógico com SDF ou netlist físico com SDF)
- Rodar com ou sem interface gráfica (SimVision)

#### Genus
<a name="genus"></a>

Para a síntese lógica o software Genus pode ser utilizado. Caso o programa seja escolhido, duas opções podem ser selecionadas, rodar com ou sem DFT (Design for Test). Caso a opção sem DFT seja selecionada, temos a exclusão de algumas células scan da disponibilidade para uso.

- Selecionar se o Genus executará com ou sem DFT
- Executa o Genus com a frequência determinada


#### Innovus
<a name="innovus"></a>

Para a síntese física o software Innovus pode ser utilizado. Sua execução é simplificada, apenas executando o programa com a frequência escolhida


### Organização das Pastas
<a name="organiza"></a>

Algumas modificações foram feitas na estrutura dos diretórios para maior organização. Como os softwares criam arquivos para as execuções, foi adicionada uma pasta work ao diretório frontend para a execução do software Xcelium. Além disso, uma pasta deliverables foi adicionada para armazenar os arquivos VCDs gerados pelas simulações. Assim, as pastas estão organizadas na seguinte configuração

- Multiplier32FP        - (diretório raiz)
    - backend           - (diretório de backend)
        - layout        - (diretório dos resultados da síntese física)
            - constraints
            - deliverables
            - reports
            - scripts
            - work      - (diretório para execução do Innovus)
        - synthesis      - (diretório dos resultados da síntese lógica)
            - constraints
            - deliverables
            - reports
            - scripts
                - common
            - work      - (diretório para execução do Genus)
        - verification  - (diretório dos resultados da verificação física)
            - work      - (diretório para execução do Assura)
    - frontend          - (diretório de frontend)
        - work          - (diretório para execução do Xcelium)
        - deliverables

### IEEE 754
<a name="ieee"></a>

O padrão IEEE 754 define números em ponto flutuante de 32 bits. Sua estrutura é definida em:

- 1 bit de sinal;
- 8 bits de expoente;
- 23 bits de mantissa.

Com isso temos uma estrutura:

{1'b0, 8'b00000000, 23'b0}

Para efetuar a multiplicação devemos execultar o seguinte procedimento:

- Executar a função XOR entre os bits de sinal de ambos os números;
- Somar os expoentes e subtrair o bias (127 para número normalizado e 126 para desnormalizado);
- adicionar um bit à esquerda da mantissa (1 se normalizado, 0 se desnormalizado);
- efetuar a multiplicação das mantissas (resultado com 48 bits)
- caso o bit 47 (considerando o bit 0) seja 1, é necessário realizar um deslocamento à direita da mantissa e somar 1 ao resultado do expoente;
- concatenar os resultados de sinal, expoente e mantissa (do bit 45 ao 23).

Algumas considerações são relevantes. No padrão IEEE alguns valores são reservados. Dentre eles podemos destacar:

- infinito: expoente com todos os valores em alto e a mantissa igual a zero;
- NaN (Not-a-Number): expoente com todos os valores em alto e a mantissa diferente de zero:
- desnormalizado: expoente com todos os valores em baixo e mantissa diferente de zero

Os casos de overflow ocorrem quando o expoente passa de 0x11111110 (0x11111111 é valor reservado). Se considerarmos uma soma de dois números que passe de 0d255, com 8 bits teremos um estouro, e com isso será dificil identificar underflow.

Para operar com números desnormalizados há a necessidade de considerar o resultado da operação do expoente podendo ser negativo. Com isso é possível retorno de números denormalizados no resultado da multiplicação. Para isso, devemos considerar o valor do resultado da soma dos expoentes removendo o bias e ver qual valor negativo que foi alcançado, com isso, basta considerarmos o valor do resultado para determinar o número de deslocamentos da mantissa que permita o resultado correto do número desnormalizado.

O caso de underflow envolve o resultado ser menor que o menor número desnormalizado (0x00000001 ou 1*2^-149), assim sendo interessante a verificação de expoentes negativos.

Com as condições supracitadas, verificamos que o expoente deve permitir números maiores que 0d255 e menores que zero, assim, o resultado da soma dos expoentes deve ter no mínimo 10 bits, sendo o mais significativo utilizado para identificar valores negativos.
