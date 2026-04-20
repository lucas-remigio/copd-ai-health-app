# AI-Enhanced Mobile App para Reabilitação Pulmonar Híbrida

## Apresentação: Modelo AI Local vs Cloud

**Duração:** 10 minutos | **Objetivo:** Debate sobre potencial clínico

---

## 📱 1. INTRODUÇÃO (1 min)

### O Problema

- Pacientes com doenças pulmonares necessitam de reabilitação contínua
- Programas presenciais: adesão de apenas 30-40%
- Falta de monitorização personalizada no dia-a-dia
- Dados de saúde sensíveis requerem privacidade máxima

### Nossa Solução

**App móvel com AI local** que funciona como assistente pessoal de reabilitação, disponível 24/7, **sem necessidade de internet**.

---

## 🏗️ 2. ARQUITETURA DA APLICAÇÃO (2 min)

### Componentes Principais

#### **Interface em 3 Tabs**

1. **Passos/Atividade**
   - Contagem automática de passos (Android HealthConnect)
   - Definição de metas personalizadas
   - Visualização de progresso diário
   - Método de transporte atual (caminhada/corrida/bicicleta)

2. **Locais Próximos**
   - Integração Google Maps API
   - Sugestões baseadas em localização
   - Distância em passos e duração estimada
   - Navegação direta para o destino

3. **Chat com AI**
   - Conversação natural em português
   - Recomendações contextuais
   - Histórico persistente
   - Streaming de respostas em tempo real

#### **Motor AI Local**

- **Modelo:** Gemma 3 (1B ou 3B parâmetros)
- **Formato:** GGUF quantizado (Q4_K_M)
- **Tamanho:** 768 MB (1B) ou 2.6 GB (3B)
- **Inferência:** 100% on-device via llama.cpp

---

## 🔐 3. VANTAGENS DO MODELO LOCAL (3 min)

### **A. Privacidade e Conformidade GDPR**

| Aspeto                    | Cloud AI             | **Local AI** ✅   |
| ------------------------- | -------------------- | ----------------- |
| Dados transmitidos        | Sim, sempre          | **Nunca**         |
| Armazenamento externo     | Servidores terceiros | **Device only**   |
| Rastreamento possível     | Sim                  | **Impossível**    |
| Conformidade GDPR         | Complexa             | **Automática**    |
| Consentimento dados saúde | Obrigatório          | **Não aplicável** |

**Para reabilitação pulmonar:**

- Dados de mobilidade = dados de saúde (GDPR Artigo 9)
- Pacientes com doenças crónicas: proteção extra necessária
- Zero risco de vazamento de informação clínica

### **B. Disponibilidade e Autonomia**

```
Cloud AI:
📶 Internet ──> ⚡ API Call ──> ☁️ Server ──> 📥 Response
   ❌ 4G/5G      ❌ Custo      ❌ Latency    ❌ Downtime

Local AI:
📱 Device ──> 🧠 Model ──> 💬 Response
   ✅ Offline    ✅ Grátis   ✅ <1s
```

**Casos de uso críticos:**

- Paciente em zona rural sem cobertura
- Caminhadas em parques/montanhas
- Viagens internacionais (roaming caro)
- Falhas de servidores cloud (SLA 99.9% = 8h/ano down)

### **C. Custo Zero de Operação**

| Modelo          | Custo/1M tokens | **100 utilizadores/dia** | **1000 utilizadores/dia** |
| --------------- | --------------- | ------------------------ | ------------------------- |
| GPT-4           | $30             | **$900/mês**             | **$9,000/mês**            |
| GPT-3.5         | $2              | **$60/mês**              | **$600/mês**              |
| Claude          | $15             | **$450/mês**             | **$4,500/mês**            |
| **Gemma Local** | **€0**          | **€0**                   | **€0**                    |

**Para sistema de saúde público:** Escalabilidade sem custo marginal.

### **D. Latência e Experiência**

- **Cloud:** 500-2000ms (rede + processamento)
- **Local:** 50-200ms (apenas processamento)
- **Streaming:** Tokens aparecem instantaneamente
- **UX:** Sensação de conversação natural

---

## 🏥 4. APLICAÇÃO NA REABILITAÇÃO PULMONAR (2 min)

### **Funcionalidades Específicas**

#### **Recomendações Contextuais**

```
Entrada AI:
- Passos hoje: 1,250
- Meta: 5,000 passos
- Locais próximos: Parque (2,800 passos), Café (800 passos)

Resposta AI:
"Para atingir a tua meta, sugiro caminhares até ao Parque!
São 2,800 passos (~28 min), perfeito para a tua capacidade atual.
Podes descansar lá antes de voltar. 💪"
```

#### **Monitorização Contínua**

- Contagem automática sem intervenção
- Alertas para inatividade prolongada
- Ajuste dinâmico de metas baseado em progresso
- Histórico para análise clínica

#### **Motivação Personalizada**

- Chat sempre disponível para encorajamento
- Sugestões de locais interessantes
- Gamificação subtil (metas, progresso visual)

### **Protocolo Clínico Integrado**

**Fase 1: Avaliação Inicial**

- Fisioterapeuta define meta inicial (ex: 3,000 passos)
- App monitoriza durante 1 semana

**Fase 2: Ajuste Progressivo**

- AI sugere locais que aumentam gradualmente distância
- Paciente ganha confiança e autonomia

**Fase 3: Manutenção**

- Monitorização contínua sem custo
- Intervenção humana apenas quando necessário

---

## 🔬 5. LIMITAÇÕES E DESAFIOS (1 min)

### **Técnicas**

- Modelo 1B: Capacidade linguística limitada
- Português: Menos treino que inglês
- Consumo bateria: ~15-20% por sessão intensiva
- Espaço armazenamento: 768 MB - 2.6 GB

### **Clínicas**

- Não substitui avaliação médica
- Requer supervisão inicial
- Necessita validação em trials clínicos

### **Soluções Implementadas**

- Prompt engineering otimizado para português
- Formato Gemma chat template
- Streaming para reduzir perceived latency
- Sistema de cache para resposta rápida

---

## 🚀 6. POSSIBILIDADES FUTURAS (1 min)

### **Curto Prazo**

- ✅ Integração sensores wearables (FC, SpO2)
- ✅ Exportação de dados para médico
- ✅ Alertas baseados em padrões anormais
- ✅ Multi-idioma (fine-tuning)

### **Médio Prazo**

- 🔄 Fine-tuning com dados de reabilitação pulmonar
- 🔄 Modelo específico para português médico
- 🔄 Reconhecimento de voz para input
- 🔄 Análise de tosse/dispneia via áudio

### **Longo Prazo**

- 🎯 Predição de exacerbações
- 🎯 Recomendações farmacológicas básicas
- 🎯 Integração com registos eletrónicos de saúde
- 🎯 Estudos multicêntricos com dados anonimizados

---

## 💡 7. CONCLUSÃO E DEBATE (30s)

### **Tese Principal**

**AI local não é apenas viável - é superior para aplicações de saúde.**

### **Pilares**

1. 🔐 **Privacidade**: Zero transmissão de dados sensíveis
2. 📡 **Autonomia**: Funciona sempre, em qualquer lugar
3. 💰 **Sustentabilidade**: Custo zero para escalar
4. ⚡ **Performance**: Respostas instantâneas

### **Questões para Debate**

1. Como validar eficácia clínica vs programas tradicionais?
2. Regulação: App médico (Classe I/IIa) ou bem-estar?
3. Como garantir uso correto sem supervisão excessiva?
4. Fine-tuning ético: dados de pacientes vs privacidade?
5. Integração com SNS: viável? Desejável?

---

## 📊 DEMO AO VIVO

**Cenário:** Paciente com DPOC moderada, meta 5,000 passos/dia

1. Mostrar contagem automática de passos
2. Visualizar locais próximos com distâncias
3. Perguntar ao AI: "Onde posso ir hoje para cumprir a minha meta?"
4. Demonstrar resposta em streaming (sem internet!)
5. Navegar para local sugerido via Google Maps

**Tempo demo:** 2 minutos

---

## 📚 REFERÊNCIAS TÉCNICAS

### Stack Tecnológico

- **Frontend:** Flutter (Dart) - multiplataforma
- **AI Engine:** llama.cpp (C++) via llama_flutter_android
- **Health Data:** Android HealthConnect API
- **Maps:** Google Maps/Places API
- **State Management:** Singleton pattern (reactive streams)

### Modelos Testados

1. **Gemma 3 1B** (atual): 768 MB, rápido mas limitado
2. **Gemma 3N 3B** (recomendado): 2.6 GB, capacidade superior
3. **Qwen 2.5** (alternativa): Melhor português

### Open Source

- Código disponível: `github.com/lucas-remigio/copd_ai_health_app`
- Licença: MIT
- Contribuições bem-vindas

---

## 🎯 CALL TO ACTION

### Para Clínicos

- Feedback sobre protocolo
- Participação em trial piloto
- Definição de métricas de sucesso

### Para Programadores

- Contribuições no repositório
- Fine-tuning de modelos
- Testes de usabilidade

### Para Investigadores

- Colaboração em publicação
- Design de estudo clínico
- Análise de dados agregados

---

**Contacto:**

- Email: lucas.remigio@example.com
- GitHub: @lucas-remigio
- LinkedIn: Lucas Remígio

**Obrigado! Perguntas?** 🙋‍♂️
