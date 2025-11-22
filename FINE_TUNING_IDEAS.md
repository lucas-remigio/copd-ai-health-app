# Fine-Tuning do Modelo AI para Reabilitação Pulmonar

---

## 🎯 ESTRATÉGIA DE IMPLEMENTAÇÃO

### Abordagem Recomendada: **Fine-tuning Incremental**

Em vez de criar um dataset massivo desde o início, recomendamos uma estratégia iterativa e ágil que permite validação rápida e reduz risco:

---

### **🚀 Fase 1: MVP Dataset (Semanas 1-4)**

**Objetivo:** Testar viabilidade com dataset mínimo focado nas features core da app.

```python
# Sprint 1: Dataset mínimo viável
mvp_categories = {
    "walking_recommendations": 500,  # Core da app
    "goal_adjustment": 300,          # Feature já existente
    "basic_motivation": 200          # Essencial para engagement
}
# Total: 1,000 exemplos (1 semana para gerar com GPT-4)
```

**Deliverables:**

- ✅ 1,000 exemplos validados por fisioterapeuta
- ✅ Modelo fine-tuned em Gemma 2B (Q4_K_M ~1.5GB)
- ✅ Deploy na app para 10-20 utilizadores beta
- ✅ Recolha de feedback durante 2 semanas

---

### **📈 Fase 2: Expansão Baseada em Feedback (Semanas 5-8)**

**Objetivo:** Adicionar categorias com maior impacto clínico baseado em necessidades reais dos utilizadores.

```python
# Sprint 2: Expandir complexidade
expanded_categories = {
    # Manter dataset MVP
    "walking_recommendations": 500,
    "goal_adjustment": 300,
    "basic_motivation": 200,

    # Adicionar novas categorias
    "symptom_management": 1,000,    # Feedback: utilizadores pedem ajuda com sintomas
    "patient_education": 500,       # Feedback: dúvidas sobre técnicas respiratórias
    "emotional_support": 300        # Feedback: necessidade de suporte psicológico
}
# Total acumulado: 2,800 exemplos
```

**Método:** Continue fine-tuning incremental em cima do modelo da Fase 1 (não treinar do zero).

**Vantagens:**

- ✅ Preserva aprendizagem anterior
- ✅ Convergência mais rápida
- ✅ Menos risco de overfitting

---

### **🏥 Fase 3: Especialização Clínica (Semanas 9-16)**

**Objetivo:** Adicionar features avançadas de deteção de risco e personalização.

```python
# Sprint 3+: Features clínicas avançadas
advanced_categories = {
    # Dataset anterior: 2,800 exemplos

    # Novas categorias críticas
    "risk_detection": 500,          # Detetar exacerbações
    "exercise_library": 400,        # Instruções passo-a-passo
    "wearable_interpretation": 300, # SpO2, FC
    "conversation_diary": 300       # Extração estruturada de sintomas
}
# Total final: 4,300 exemplos
```

---

### **📊 Comparação de Abordagens**

| Abordagem          | Tempo até 1º Teste | Custo Inicial | Risco | Flexibilidade | Qualidade Final     |
| ------------------ | ------------------ | ------------- | ----- | ------------- | ------------------- |
| **Incremental** ⭐ | 2 semanas          | €500          | Baixo | ⭐⭐⭐⭐⭐    | Alta (iterativa)    |
| Multi-Task         | 6 semanas          | €2,500        | Médio | ⭐⭐⭐        | Alta (se funcionar) |
| Especializado      | 8 semanas          | €3,000+       | Alto  | ⭐            | Variável            |

---

### **💡 Porquê Incremental?**

1. **Feedback Rápido:** Testar hipóteses em 2 semanas vs 6 semanas
2. **Menor Investimento Inicial:** €500 vs €2,500 upfront
3. **Aprendizagem Contínua:** Cada iteração informa a próxima
4. **Menor Desperdício:** Só investes em categorias que provam valor
5. **Melhor Produto:** Modelo evolui com necessidades reais, não assumidas

---

### **🎓 Decisão: NÃO fazer tudo em simultâneo**

**❌ Evitar:** Criar dataset de 10,000 exemplos antes de validar com utilizadores reais.

**✅ Fazer:**

```
Semana 1-2:   Gerar MVP (1,000 exemplos)
Semana 3:     Fine-tune inicial
Semana 4:     Deploy e testar com 10 utilizadores
Semana 5-6:   Analisar feedback, identificar gaps
Semana 7-8:   Gerar dataset adicional (categorias prioritárias)
Semana 9:     Continue training
Semana 10-12: Re-deploy e validar melhorias
...
```

**Exemplo de decisão baseada em dados:**

```python
# Após 2 semanas de testes
user_feedback = {
    "walking_recommendations": {"satisfaction": 4.2, "usage": 85%},  # ✅ Funciona bem
    "goal_adjustment": {"satisfaction": 3.8, "usage": 60%},          # ⚠️ Precisa melhoria
    "symptom_questions": {"count": 45, "unanswered": 32}             # ❗ Gap crítico
}

# Decisão: Priorizar dataset de symptom_management na Fase 2
next_sprint_focus = "symptom_management"  # 1,000 exemplos
```

---

### **🚀 Plano de Ação Concreto**

#### **Esta Semana:**

```bash
# 1. Configurar ambiente
pip install openai transformers datasets

# 2. Gerar primeiros 1,000 exemplos
python scripts/generate_mvp_dataset.py --categories walking,goals,motivation --output mvp_1000.json

# 3. Validação médica (4-8 horas com fisioterapeuta)
python scripts/review_dataset.py --input mvp_1000.json
```

#### **Próxima Semana:**

```bash
# 4. Fine-tune em Google Colab (grátis)
python scripts/finetune_gemma.py --base google/gemma-2b-it --data mvp_1000_validated.json

# 5. Quantizar para mobile
python scripts/convert_to_gguf.py --model gemma-rehab-mvp --quant Q4_K_M
```

#### **Semana 3-4:**

```dart
// 6. Deploy na app
final aiService = AILlamaService(
  model: AIModelConfig(
    name: 'Gemma Rehab MVP',
    url: 'https://your-server.com/gemma-rehab-mvp-Q4_K_M.gguf',
    fileName: 'gemma-rehab-mvp-Q4_K_M.gguf',
    fallbackSizeBytes: 1658273792, // ~1.5GB
    description: 'MVP fine-tuned para reabilitação pulmonar',
  )
);

// 7. A/B test: 10 users com modelo fine-tuned vs 10 com base model
```

---

## 📊 Ideias de Especialização e Dataset

---

## 🎯 1. OBJETIVOS DO FINE-TUNING

### A. Domínio Específico

- **Linguagem médica portuguesa**: Termos como DPOC, dispneia, saturação O2, espirometria
- **Contexto de reabilitação**: Exercícios respiratórios, técnicas de conservação de energia
- **Motivação terapêutica**: Tom encorajador mas realista, sem minimizar dificuldades

### B. Tarefas Específicas da App

1. **Recomendação de caminhadas** baseada em capacidade atual
2. **Interpretação de sintomas** (fadiga, falta de ar)
3. **Ajuste de metas** progressivo e seguro
4. **Educação do paciente** sobre gestão da doença
5. **Detecção de sinais de alerta** (exacerbação)

---

## 📊 2. DATASET PARA FINE-TUNING

### **A. Conversações Sintéticas (5,000-10,000 exemplos)**

#### Formato Base

```json
{
  "conversations": [
    {
      "user": "Hoje consegui fazer 2000 passos, mas sinto-me muito cansado",
      "assistant": "É normal sentires-te cansado após 2000 passos, especialmente se é mais do que costumas fazer. O importante é que conseguiste! Amanhã tenta o mesmo número ou até um pouco menos para recuperares. A progressão deve ser gradual. Como está a tua respiração agora?",
      "context": {
        "steps_today": 2000,
        "goal": 3000,
        "days_active": 5,
        "condition": "DPOC moderada"
      }
    }
  ]
}
```

#### **Categoria 1: Recomendações de Caminhada (30%)**

**Cenários:**

- Paciente iniciante (< 1000 passos/dia)
- Paciente moderado (1000-3000 passos/dia)
- Paciente avançado (> 3000 passos/dia)
- Dias de baixa energia
- Condições climáticas adversas (calor, frio, poluição)

**Exemplo:**

```
User: Onde posso ir hoje para cumprir a minha meta de 3500 passos?
Context: steps=800, goal=3500, nearby=[Parque 2km, Café 500m, Supermercado 1.5km]
Assistant: Sugiro dividires em 2 caminhadas hoje! Pela manhã vai ao
Supermercado (1500 passos) e à tarde ao Café (500 passos). Assim chegas
aos 2800 passos sem te cansares demasiado. Se te sentires bem, podes
adicionar uma volta curta perto de casa para atingir a meta. 🚶‍♂️
```

#### **Categoria 2: Gestão de Sintomas (25%)**

**Sintomas a cobrir:**

- Dispneia (falta de ar)
- Fadiga excessiva
- Tosse produtiva vs seca
- Chiado no peito
- Dor torácica (RED FLAG)
- Palpitações
- Tonturas

**Exemplo:**

```
User: Durante a caminhada senti falta de ar e tive que parar 3 vezes
Assistant: É importante ouvires o teu corpo. Falta de ar durante o
exercício é normal em DPOC, mas parar 3 vezes indica que a intensidade
foi alta. Para a próxima:
1. Reduz o ritmo - caminha mais devagar
2. Usa a técnica dos lábios franzidos ao expirar
3. Faz pausas programadas (ex: a cada 5 minutos)
Se a falta de ar não melhorar com repouso ou vier com dor no peito,
contacta o teu médico. Como te sentes agora?
```

#### **Categoria 3: Ajuste de Metas (20%)**

**Lógica de progressão:**

- Aumentar 10-15% por semana se consistente
- Reduzir 20-30% após exacerbação
- Manter se houve >2 sintomas adversos

**Exemplo:**

```
User: Tenho cumprido a meta de 2500 passos todos os dias esta semana!
Assistant: Fantástico! 7 dias seguidos é um marco importante! 🎉
Estás pronto para aumentar gradualmente. Sugiro nova meta de 2800 passos
para a próxima semana (aumento de 12%). Continua a ouvir o teu corpo -
se num dia te sentires mais cansado, não há problema em fazer menos.
O progresso não é linear, mas estás no caminho certo!
```

#### **Categoria 4: Educação e Técnicas (15%)**

**Tópicos:**

- Respiração diafragmática
- Técnica de lábios franzidos (pursed-lip breathing)
- Conservação de energia
- Importância da hidratação
- Quando usar broncodilatador
- Reconhecer exacerbação

**Exemplo:**

```
User: O que é a técnica dos lábios franzidos?
Assistant: É uma técnica que ajuda a controlar a falta de ar! Funciona
assim:
1. Inspira pelo nariz (2 segundos)
2. Franze os lábios como se fosses assobiar
3. Expira devagar pelos lábios franzidos (4 segundos)

Usa durante caminhadas e quando sentires falta de ar. Ajuda a manter
as vias aéreas abertas e a expirar melhor o CO2. Pratica agora, enquanto
estás descansado, para ser mais fácil usar quando precisares! 💨
```

#### **Categoria 5: Motivação e Suporte Emocional (10%)**

**Situações:**

- Dias sem progresso
- Recaídas após exacerbação
- Frustração com limitações
- Celebração de conquistas
- Ansiedade sobre progressão da doença

**Exemplo:**

```
User: Já não aguento ter esta doença. Fico cansado por tudo.
Assistant: É compreensível sentires-te frustrado. Viver com DPOC é
desafiante e estes sentimentos são válidos. Mas lembra-te: há 3 semanas
fazias 1200 passos e hoje fizeste 2100. Isso é progresso real! Cada
passo conta. A reabilitação não cura, mas dá-te mais independência e
qualidade de vida. Tens apoio psicológico disponível? Falar com alguém
pode ajudar. Eu estarei aqui sempre que precisares. 💙
```

---

## 🏥 3. FEATURES ESPECÍFICAS PARA INTEGRAR NA APP

### **A. Detecção de Padrões de Risco**

**Fine-tune para reconhecer:**

```python
# Dataset de sinais de alerta
{
  "input": "Há 3 dias que ando mais cansado e a expetoração está amarela",
  "output": "⚠️ Estes sintomas podem indicar uma exacerbação (agravamento).
  É importante contactares o teu médico nas próximas 24h. Enquanto isso:
  - Descansa e não forces exercício
  - Mantém hidratação
  - Usa o teu inalador conforme prescrito
  Devo notificar o teu fisioterapeuta através da app?",
  "classification": "exacerbation_risk",
  "urgency": "medium"
}
```

**Implementação na app:**

- Sistema de alertas baseado em palavras-chave
- Botão para contactar equipa médica
- Escalation automático se sintomas RED FLAG

### **B. Planos de Caminhada Adaptativos**

**Fine-tune com séries temporais:**

```json
{
  "patient_history": [
    {"day": 1, "steps": 1500, "symptoms": "none"},
    {"day": 2, "steps": 1800, "symptoms": "mild_fatigue"},
    {"day": 3, "steps": 1200, "symptoms": "dyspnea"},
    {"day": 4, "steps": 1000, "symptoms": "dyspnea"}
  ],
  "recommendation": "O teu padrão mostra que aumentaste muito rápido.
  Vamos estabilizar em 1200 passos durante 4 dias. Se te sentires bem,
  voltamos aos 1500. A recuperação não é falhar - é ser inteligente!"
}
```

**Implementação na app:**

- Análise de tendência de 7 dias
- Sugestões proativas baseadas em padrões
- Gráficos de correlação passos/sintomas

### **C. Biblioteca de Exercícios Respiratórios**

**Dataset com instruções passo-a-passo:**

```
User: Podes ensinar-me um exercício para fortalecer a respiração?
Assistant: Claro! Vamos fazer respiração diafragmática:

📍 Posição: Sentado ou deitado confortavelmente
⏱️ Duração: 5-10 minutos, 2x por dia

Passo a passo:
1. Coloca uma mão no peito e outra na barriga
2. Inspira pelo nariz - a mão da barriga deve subir mais que a do peito
3. Expira devagar pela boca - a barriga desce
4. Repete 10 vezes

Queres que te lembre de praticar? Posso enviar notificação 2x/dia.
```

**Implementação na app:**

- Vídeos ou animações dos exercícios
- Timer integrado
- Sistema de lembretes personalizável
- Track de exercícios completados

### **D. Interpretação de Métricas de Wearables**

**Fine-tune com dados de sensores:**

```json
{
  "metrics": {
    "heart_rate": 110,
    "spo2": 91,
    "steps": 500,
    "activity_duration": "15min"
  },
  "interpretation": "A tua frequência cardíaca subiu para 110 durante a
  caminhada, o que é normal para exercício moderado. No entanto, a saturação
  de oxigénio desceu para 91%. Isto pode indicar que a intensidade foi alta.
  Para a próxima, reduz o ritmo e faz pausas se a SpO2 descer abaixo de 90%.
  Se isto continuar a acontecer, fala com o teu médico - pode ser necessário
  ajustar a medicação ou usar oxigénio suplementar durante exercício."
}
```

**Implementação na app:**

- Integração Bluetooth com oxímetros/smartwatches
- Alertas em tempo real durante atividade
- Relatórios para médico com correlações

### **E. Diário de Sintomas Guiado**

**Fine-tune para extrair informação estruturada:**

```
User: Hoje acordei com mais tosse que o normal
Assistant: Vou registar isso. Algumas perguntas para o diário:
1. A tosse é seca ou com expetoração? [seca/produtiva]
2. Que cor tem a expetoração? [clara/branca/amarela/verde]
3. Numa escala de 1-10, quão incomodativa é? [1-10]
4. Notaste febre ou arrepios? [sim/não]

✅ Registado: Tosse produtiva, expetoração amarela, intensidade 6/10
Isto pode ser sinal de infeção. Recomendo consultar médico se piorar ou
persistir >48h.
```

**Implementação na app:**

- Formulários conversacionais (vs questionários chatos)
- Exportação PDF para médico
- Visualização timeline de sintomas

---

## 🧪 4. PIPELINE DE FINE-TUNING

### **Passo 1: Criação do Dataset**

```python
# Script para gerar conversações sintéticas
from openai import OpenAI  # Usar GPT-4 para gerar exemplos

client = OpenAI()

def generate_training_examples(scenario, n=100):
    prompt = f"""
    Generate {n} realistic conversations between a COPD patient and a
    Portuguese health AI assistant for the scenario: {scenario}

    Format: JSON with user, assistant, context fields
    Language: Portuguese (Portugal)
    Tone: Empathetic, medically accurate, motivating
    """

    response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "system", "content": prompt}]
    )

    return parse_json(response)

# Gerar para cada categoria
scenarios = [
    "walking_recommendations",
    "symptom_management",
    "goal_adjustment",
    "patient_education",
    "emotional_support"
]

dataset = []
for scenario in scenarios:
    dataset.extend(generate_training_examples(scenario, n=1000))
```

### **Passo 2: Curadoria e Validação**

- **Revisão médica**: Fisioterapeuta valida accuracy
- **Revisão linguística**: Nativo PT valida naturalidade
- **Teste de segurança**: Remover conselhos perigosos

### **Passo 3: Fine-Tuning do Gemma**

```python
# Usando Hugging Face Transformers
from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments
from trl import SFTTrainer

# Load base model
model = AutoModelForCausalLM.from_pretrained("google/gemma-2b-it")
tokenizer = AutoTokenizer.from_pretrained("google/gemma-2b-it")

# Prepare dataset
def format_conversation(example):
    return f"""<start_of_turn>user
{example['user']}<end_of_turn>
<start_of_turn>model
{example['assistant']}<end_of_turn>"""

# Training
trainer = SFTTrainer(
    model=model,
    train_dataset=dataset,
    formatting_func=format_conversation,
    max_seq_length=2048,
    args=TrainingArguments(
        output_dir="./gemma-pulmonary-rehab",
        num_train_epochs=3,
        per_device_train_batch_size=4,
        learning_rate=2e-5,
        save_strategy="epoch"
    )
)

trainer.train()
```

### **Passo 4: Quantização para Mobile**

```bash
# Converter para GGUF e quantizar
python convert_hf_to_gguf.py gemma-pulmonary-rehab \
  --outfile gemma-rehab.gguf \
  --outtype f16

./llama-quantize gemma-rehab.gguf \
  gemma-rehab-Q4_K_M.gguf Q4_K_M
```

**Tamanho esperado:** ~1.5 GB (Gemma 2B quantizado)

### **Passo 5: Testes A/B**

```
Grupo A: Gemma base (controlo)
Grupo B: Gemma fine-tuned
Métricas:
- Relevância das respostas (escala Likert 1-5)
- Adherence à app (dias de uso consecutivos)
- Satisfação do paciente
- Segurança (respostas perigosas = 0 tolerância)
```

---

## 🔬 5. DATASETS PÚBLICOS PARA TREINO

### **A. Dados Médicos em Português**

- **PubMed PT**: Abstracts de artigos em português
- **UMLS Portuguese**: Terminologia médica
- **DiaBL@**: Dataset de blogs de saúde PT

### **B. Conversações de Saúde (traduzir/adaptar)**

- **MedDialog**: 3.5M conversações médico-paciente
- **HealthCareMagic**: 200k Q&A médicas
- **Nota**: Traduzir com cuidado e validar medicamente

### **C. Criar Próprio Dataset**

- **Colaboração com hospitais**: Logs anonimizados (GDPR-compliant)
- **Simulação com ChatGPT**: Gerar 10k exemplos sintéticos
- **Crowdsourcing**: Fisioterapeutas criam exemplos

---

## 💡 6. IDEIAS AVANÇADAS

### **A. Multi-Task Learning**

Fine-tune para múltiplas tarefas simultaneamente:

```python
tasks = {
    "conversation": 0.4,      # 40% conversação livre
    "classification": 0.2,     # 20% classificar sintomas
    "recommendation": 0.2,     # 20% sugerir caminhadas
    "education": 0.1,          # 10% ensinar técnicas
    "summarization": 0.1       # 10% resumir progresso
}
```

### **B. Reinforcement Learning from Human Feedback (RLHF)**

```
1. Modelo gera respostas
2. Fisioterapeutas ranqueiam qualidade
3. Modelo aprende a maximizar score
4. Iteração contínua com feedback real de pacientes
```

### **C. Few-Shot Adaptation**

```python
# Prompt com exemplos do próprio paciente
def personalized_prompt(patient_id, new_question):
    history = get_last_5_interactions(patient_id)
    return f"""
    Histórico do paciente:
    {history}

    Nova pergunta: {new_question}
    Responde considerando o contexto específico deste paciente.
    """
```

### **D. Modelo de Embeddings para Busca**

```python
# Criar FAQ pesquisável
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('sentence-transformers/paraphrase-multilingual-mpnet-base-v2')

faq = [
    "Como fazer respiração diafragmática?",
    "Quando devo contactar o médico?",
    "Posso fazer exercício com falta de ar?",
    # ... 200+ perguntas
]

embeddings = model.encode(faq)

# Na app, buscar resposta mais relevante
user_query = "tenho falta de ar, posso caminhar?"
query_embedding = model.encode([user_query])
best_match = find_most_similar(query_embedding, embeddings)
```

---

## 📈 7. MÉTRICAS DE SUCESSO DO FINE-TUNING

### **Automáticas**

- **Perplexity**: < 15 (modelo entende português médico)
- **BLEU score**: > 40 (respostas similares a humano)
- **Safety score**: 100% (zero conselhos perigosos)

### **Clínicas**

- **Adherence**: +30% vs app sem AI
- **Progressão**: Pacientes atingem metas 20% mais rápido
- **Satisfação**: NPS > 50
- **Segurança**: 0 eventos adversos atribuíveis à app

### **Técnicas**

- **Latência**: < 200ms para primeira token
- **Bateria**: < 5% consumo por sessão 15min
- **Tamanho**: < 2 GB (modelo + dados)

---

## 🚀 8. ROADMAP DE IMPLEMENTAÇÃO

### **Fase 1: Proof of Concept (3 meses)**

- [ ] Gerar 5,000 exemplos sintéticos
- [ ] Fine-tune Gemma 2B
- [ ] Testar com 10 pacientes voluntários
- [ ] Iterar baseado em feedback

### **Fase 2: Validação Clínica (6 meses)**

- [ ] Dataset de 20,000 exemplos
- [ ] Trial com 100 pacientes (2 grupos)
- [ ] Análise estatística de eficácia
- [ ] Publicação de resultados

### **Fase 3: Escalamento (12 meses)**

- [ ] RLHF com 1000+ pacientes
- [ ] Multi-idioma (EN, ES)
- [ ] Integração com wearables
- [ ] Certificação como dispositivo médico

---

## 💰 9. ESTIMATIVA DE CUSTOS

### **Criação do Dataset**

- GPT-4 API (10k exemplos): ~$200
- Validação médica (40h @ €50/h): €2,000
- **Total:** €2,200

### **Compute para Fine-Tuning**

- GPU A100 (48h @ $2/h): $96
- Ou Google Colab Pro: $10/mês
- **Total:** ~$100

### **Infraestrutura Zero Após Deploy**

- Modelo roda on-device
- **Custo marginal por usuário:** €0

**ROI:** Dataset serve para milhares de pacientes sem custo adicional!

---

## 🎯 CONCLUSÃO

**Fine-tuning é viável e essencial** para esta aplicação porque:

1. ✅ **Qualidade**: Respostas específicas para reabilitação pulmonar
2. ✅ **Segurança**: Treino controlado evita conselhos perigosos
3. ✅ **Português**: Melhora dramática vs modelo base
4. ✅ **Custo**: Investimento único (~€2,500) para benefício perpétuo
5. ✅ **Privacidade**: Modelo permanece local após treino

**Próximo passo:** Começar com 1,000 exemplos sintéticos, validar com fisioterapeutas, e iterar rapidamente com feedback real.
