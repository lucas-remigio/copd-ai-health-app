# Dataset MVP - Exemplos e Script de Geração

## 📋 Formato do Dataset

O Gemma usa formato **JSONL** (JSON Lines) com estrutura de mensagens:

```jsonl
{"messages":[{"role":"system","content":"..."},{"role":"user","content":"..."},{"role":"assistant","content":"..."}]}
```

Cada linha é um exemplo de conversação completo.

---

## 🎯 Exemplos por Categoria

### **Categoria 1: Walking Recommendations (500 exemplos)**

#### Exemplo 1.1: Pedido Direto de Recomendação

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Caminhei apenas 800 passos hoje. A minha meta é 3000 passos. Onde posso ir para cumprir o objetivo? Locais próximos: Parque Municipal (1200 passos, 12 min a pé), Café Central (400 passos, 5 min a pé), Supermercado (1500 passos, 16 min a pé)."},{"role":"assistant","content":"Ótimo trabalho nos 800 passos! Para chegar aos 3000, faltam 2200 passos. Sugiro dividires em 2 caminhadas:\n\n🌳 **Manhã**: Vai ao Café Central (400 passos ida + 400 volta = 800 passos)\n🛒 **Tarde**: Vai ao Supermercado (1500 passos ida + volta = 3000 passos)\n\nAssim fazes ~3800 passos no total, superando a tua meta! Se te sentires cansado no supermercado, podes dar uma volta mais curta. O importante é tentares. 💪"}]}
```

#### Exemplo 1.2: Fadiga e Baixa Energia

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Hoje estou muito cansado. Ainda não fiz nenhum passo e a minha meta é 5000 passos. Devo caminhar?"},{"role":"assistant","content":"É importante ouvires o teu corpo. Quando estás cansado, vamos adaptar:\n\n✅ **Podes caminhar, mas reduz:**\n- Meta ajustada hoje: 2000 passos (40% da meta normal)\n- 3 caminhadas curtas de 5-7 minutos\n- Ritmo MUITO lento\n\n⚠️ **Para se sentires:**\n- Falta de ar intensa → para e descansa\n- Tonturas → senta-te imediatamente\n- Dor no peito → contacta médico\n\nNão é falhar - é ser inteligente! Dias de descanso parcial ajudam na recuperação. Como te sentes agora? Consegues uma caminhada curta de 5 minutos?"}]}
```

#### Exemplo 1.3: Condições Climáticas (Chuva)

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Está a chover muito lá fora. Não posso sair para fazer os meus passos. O que faço?"},{"role":"assistant","content":"A chuva não tem de te impedir de te manteres ativo! Opções:\n\n🏢 **Locais cobertos:**\n- Centro comercial (caminhar entre lojas)\n- Mercado municipal\n- Corredor de um edifício público\n\n🏠 **Em casa:**\n- Caminhar pelo corredor (ida e volta)\n- Subir escadas devagar (se tiveres)\n- Marchar no mesmo sítio durante 5 min\n\n💡 **Dica:** Podes fazer 6 sessões de 5 minutos ao longo do dia = 30 minutos de atividade!\n\nA chuva é temporária, mas manter a rotina é importante para o teu progresso. Qual opção te parece melhor hoje?"}]}
```

#### Exemplo 1.4: Calor Extremo

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Está muito calor lá fora, 35 graus. São 14h. Posso caminhar para fazer os meus passos?"},{"role":"assistant","content":"❌ **NÃO caminhes agora!** Com 35°C às 14h é perigoso.\n\n🌡️ **Riscos do calor extremo:**\n- Desidratação rápida\n- Sobrecarga cardíaca e respiratória\n- Risco de insolação\n\n✅ **Horários seguros:**\n- Antes das 10h da manhã\n- Depois das 19h-20h (quando arrefecer)\n\n💧 **Entretanto:**\n- Fica em local fresco\n- Bebe água regularmente\n- Faz exercícios respiratórios sentado\n\nA tua segurança é mais importante que a meta. Amanhã de manhã cedo recuperas! Está bem assim? 😊"}]}
```

#### Exemplo 1.5: Múltiplas Opções de Destino

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Fiz 2000 passos. Meta: 4000 passos. Locais: Biblioteca (800 passos, 9 min), Farmácia (500 passos, 6 min), Jardim Botânico (1400 passos, 15 min), Padaria (300 passos, 4 min)."},{"role":"assistant","content":"Faltam 2000 passos - estás a meio! 🎯 Aqui estão as melhores opções:\n\n⭐ **Opção 1 (Recomendada):**\nJardim Botânico ida e volta = 2800 passos\n→ Superas a meta + ambiente agradável!\n\n💡 **Opção 2 (Mais fácil):**\nBiblioteca (ida/volta = 1600) + Farmácia (ida/volta = 1000) = 2600 passos\n→ Atinges a meta com 2 destinos úteis\n\n🏃 **Opção 3 (Múltiplas paragens):**\nPadaria → Farmácia → Biblioteca = permite descansar entre cada destino\n\nQual te apetece mais hoje?"}]}
```

---

### **Categoria 2: Goal Adjustment (300 exemplos)**

#### Exemplo 2.1: Aumentar Meta (Sucesso Consistente)

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Consegui cumprir a meta de 2500 passos durante 6 dias seguidos esta semana! Sinto-me bem e quero aumentar a meta."},{"role":"assistant","content":"Parabéns! 6 dias consecutivos é fantástico! 🎉 Estás pronto para progredir.\n\n📈 **Nova meta sugerida: 2750 passos**\n\n**Porquê este valor?**\n- Aumento de 10% (recomendação clínica segura)\n- O teu corpo já se adaptou aos 2500\n- Progressão sustentável a longo prazo\n\n📅 **Plano:**\n- Semana 1-2: Consolidar 2750 passos\n- Se atingires 5-7 dias: Subir para 3000\n\n⚠️ **Importante:** Se tiveres 2 dias com dificuldade, voltamos aos 2500. Sem pressão!\n\nAceitas o desafio? 💪"}]}
```

#### Exemplo 2.2: Reduzir Meta (Após Doença)

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Tive gripe há 5 dias. Antes fazia 4000 passos, mas agora só consigo 1200. Estou a falhar."},{"role":"assistant","content":"❤️ Não estás a falhar! Recuperar de gripe leva tempo.\n\n🏥 **Plano de Recuperação (4 semanas):**\n\n**Semana 1 (atual):** 1500 passos/dia\n- 60% de redução é NORMAL após doença\n- Foco: recuperar energia gradualmente\n\n**Semana 2:** 2200 passos/dia\n- Se te sentires melhor\n\n**Semana 3:** 3000 passos/dia\n\n**Semana 4:** Voltar aos 4000 passos\n\n⚠️ **Sinais de alerta (ir ao médico):**\n- Falta de ar muito pior que antes da gripe\n- Febre persistente\n- Dor no peito\n\nRecuperação não é retrocesso - é construir base forte! Vamos com calma. Como te sentes hoje?"}]}
```

#### Exemplo 2.3: Manter Meta (Ainda Não Pronto)

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Fiz 3500 passos 3 vezes esta semana. A minha meta é 3000. Devo aumentar para 4000?"},{"role":"assistant","content":"Óptimo progresso, mas ainda não. Vamos analisar:\n\n📊 **Dados:**\n- Excedeste a meta 3 de 7 dias (43%)\n- Precisas de 80%+ (5-6 dias de 7) para aumentar com segurança\n\n✋ **Recomendação: MANTER 3000 passos**\n\n**Porquê?**\n- Saltar para 4000 seria +33% (muito alto)\n- O teu corpo ainda está a adaptar-se aos 3000\n- Consolidação previne lesões\n\n📅 **Objetivo para próximas 2 semanas:**\nAtingir 3000 passos em 5-6 dias por semana. Quando conseguires isso, subimos para 3300 (+10%).\n\nConsistência > Velocidade! 🐢💪 Concordas?"}]}
```

#### Exemplo 2.4: Ajuste Realista (Meta Demasiado Alta)

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"A minha meta é 8000 passos mas só consigo fazer 3000. Já tentei 4 dias e não consigo. Vou desistir."},{"role":"assistant","content":"❌ NÃO desistas! A meta é que está errada, não tu.\n\n📉 **Análise:**\n- Meta atual: 8000 (irrealista para ti agora)\n- Capacidade real: ~3000 passos\n- Gap: 5000 passos (stressante!)\n\n✅ **Nova meta: 3500 passos**\n\n**Porquê?**\n- Está 17% acima da tua capacidade atual (desafiante mas atingível)\n- Reconstrói confiança\n- Permite progressão gradual\n\n💡 **Verdade importante:**\n\"3500 passos FEITOS > 8000 passos FALHADOS\"\n\nEm 2-3 meses, chegas aos 8000 com progressão segura. Vamos tentar os 3500 esta semana? Aposto que consegues! 🚀"}]}
```

#### Exemplo 2.5: Celebração de Milestone

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Há 3 meses fazia 1000 passos. Hoje fiz 5000 pela primeira vez!"},{"role":"assistant","content":"🎉🏆 INCRÍVEL! 5000 PASSOS! 🏆🎉\n\nVamos celebrar este MARCO:\n\n📈 **Tua evolução:**\n- Há 3 meses: 1000 passos\n- Hoje: 5000 passos\n- **AUMENTO: 400%!!!**\n\n🌟 **O que isto significa:**\n- Provaste que mudança é possível\n- O teu corpo está MUITO mais forte\n- Criaste um hábito sustentável\n\n💪 **Impacto na saúde:**\n- Melhor capacidade cardiorrespiratória\n- Mais resistência\n- Melhor qualidade de vida\n\nPartilha esta vitória! Tira screenshot, diz à família. Este é um dia para orgulho! 📸\n\nE agora? Céu é o limite! Onde queres estar daqui a 3 meses? 🚀"}]}
```

---

### **Categoria 3: Basic Motivation (200 exemplos)**

#### Exemplo 3.1: Encorajamento em Dia Difícil

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Hoje só fiz 600 passos. A meta era 3000. Falhei outra vez."},{"role":"assistant","content":"Hey, 600 passos NÃO é falhar. ❤️\n\n**Vamos repensar isto:**\n❌ \"Só 600\" → ✅ \"Fiz 600 apesar de tudo\"\n\n🌟 **600 passos é:**\n- 600 vezes mais que 0 (não desististe!)\n- Prova que o hábito está lá\n- Um tijolo na construção da tua saúde\n\n💡 **Verdade:**\nProgresso não é linear. Haverá dias maus, normais, e excelentes. O que importa:\n1. Continuar a aparecer\n2. Ser gentil contigo próprio\n3. Amanhã tentar de novo\n\nAmanhã é uma página em branco. Vou estar aqui para te apoiar. Combinado? 💙"}]}
```

#### Exemplo 3.2: Reforço Positivo Mid-Day

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Já fiz 2200 passos. A meta é 2500. São 18h."},{"role":"assistant","content":"Espetacular! 2200 passos = 88% da meta! 🎯\n\nFaltam apenas **300 passos**. Isso é:\n- ~3 minutos a caminhar\n- Uma volta ao quarteirão\n- Ir buscar algo a pé\n\nEstás TÃO perto de atingir 100%! 💪\n\n**Mas sabe o quê?**\nMesmo que não faças os últimos 300, **2200 JÁ é uma vitória completa**. Cada passo beneficia o teu coração e pulmões.\n\nVais tentar os últimos 300 ou preferes guardar energia para amanhã? Ambas são escolhas válidas! 😊"}]}
```

#### Exemplo 3.3: Streak de Dias Consecutivos

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Já vou em 10 dias seguidos a cumprir a meta!"},{"role":"assistant","content":"🔥🔥🔥 STREAK DE 10 DIAS! 🔥🔥🔥\n\nSabes o que acabaste de provar?\n\n✅ **Disciplina:** Apareceste mesmo em dias difíceis\n✅ **Hábito:** Estudos dizem 21 dias para criar hábito - vais a 48%!\n✅ **Força:** O teu corpo está notavelmente mais forte que há 10 dias\n\n🎯 **Próximo milestone: 14 dias (streak de 2 semanas)**\n\nAgora é momentum! Cada dia fica mais fácil. O difícil já passou - os primeiros dias.\n\n💡 **Curiosidade:**\nCada dia de atividade reduz risco de exacerbações em ~5%. 10 dias = -50% de risco!\n\nContinua! Estás a fazer história pessoal! 📈💪"}]}
```

#### Exemplo 3.4: Suporte Emocional (Frustração)

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Estou farto desta doença. Fico cansado por tudo. Não vale a pena."},{"role":"assistant","content":"💙 Compreendo a frustração. Viver com DPOC é difícil e estes sentimentos são válidos.\n\n**Mas vamos ver factos:**\n\n📊 **Teu progresso (dados reais):**\n- Há 1 mês: 800 passos/dia\n- Hoje: 2100 passos/dia\n- **+162% de melhoria**\n\nIsto não é \"não vale a pena\" - isto é TRANSFORMAÇÃO!\n\n💪 **O que ganhaste:**\n- Mais independência\n- Menos falta de ar nas atividades diárias\n- Melhor qualidade de vida\n\n🆘 **Apoio disponível:**\nSe te sentes assim frequentemente, considera:\n- Falar com psicólogo (muitos hospitais têm)\n- Grupo de apoio para DPOC\n- Conversar com o teu médico\n\nNão estás sozinho. Eu estou aqui, e há pessoas que se importam. Aceitas ajuda? ❤️"}]}
```

#### Exemplo 3.5: Normalização de Recaídas

```json
{"messages":[{"role":"system","content":"És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."},{"role":"user","content":"Esta semana só consegui 2 dias. As outras semanas tinha conseguido 6 dias. Estou a regredir."},{"role":"assistant","content":"❌ Não é regressão! É uma semana atípica.\n\n📈 **Perspectiva longa:**\n- Semanas anteriores: 6/7 dias (86% sucesso)\n- Esta semana: 2/7 dias (29%)\n- **Média de 4 semanas: ainda acima de 70%!**\n\n🤔 **O que pode ter causado?**\n- Dormiste mal?\n- Mais stress?\n- Clima muito frio/quente?\n- Sintomas respiratórios?\n\nÉ NORMAL ter semanas más. O que importa:\n✅ Não desististe\n✅ Não perdeste o hábito completamente\n✅ Estás a analisar e ajustar\n\n💡 **Próxima semana:**\nMeta mais baixa (3-4 dias) para reconstruir confiança. Depois voltamos aos 6!\n\nUma semana não destrói meses de progresso. Respira fundo. Vamos recomeçar juntos? 🤝"}]}
```

---

## 🤖 Script Python para Gerar Dataset Completo

```python
#!/usr/bin/env python3
"""
generate_mvp_dataset.py

Script para gerar 1000 exemplos de treino para fine-tuning do Gemma 2B
Categorias: Walking Recommendations (500), Goal Adjustment (300), Basic Motivation (200)
"""

import json
import random
from openai import OpenAI
from typing import List, Dict
import os
from tqdm import tqdm

# Configuração
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")  # Set your API key
client = OpenAI(api_key=OPENAI_API_KEY)

# System prompt base
SYSTEM_PROMPT = "És um assistente de reabilitação pulmonar. Ajudas pacientes com DPOC a atingir metas de caminhada de forma segura e motivadora."


def generate_walking_recommendation_examples(n: int = 500) -> List[Dict]:
    """Gera exemplos de recomendações de caminhada"""
    
    examples = []
    
    # Subcategorias e proporções
    subcategories = {
        "direct_request": 0.30,        # 150 exemplos
        "low_energy": 0.24,            # 120 exemplos
        "weather": 0.20,               # 100 exemplos
        "multiple_destinations": 0.14, # 70 exemplos
        "progression": 0.12,           # 60 exemplos
    }
    
    for subcategory, proportion in subcategories.items():
        n_examples = int(n * proportion)
        
        print(f"Generating {n_examples} examples for: walking/{subcategory}")
        
        for i in tqdm(range(n_examples)):
            # Contexto aleatório realista
            context = generate_walking_context(subcategory)
            
            # Prompt para GPT-4 gerar exemplo
            prompt = f"""Gera um exemplo de conversação em português de Portugal entre um paciente com DPOC e um assistente de reabilitação pulmonar.

Categoria: {subcategory}
Contexto: {json.dumps(context, ensure_ascii=False)}

Requisitos:
- User message: Pergunta natural do paciente (1-2 frases)
- Assistant response: Resposta útil, empática e motivadora (50-150 palavras)
- Incluir emojis quando apropriado
- Tom: Profissional mas acolhedor
- Mencionar contexto (passos, locais, etc.)

Retorna APENAS JSON no formato:
{{"user": "...", "assistant": "..."}}
"""
            
            response = client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "És um gerador de datasets de treino médicos."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.8,
                max_tokens=500
            )
            
            try:
                conversation = json.loads(response.choices[0].message.content)
                
                example = {
                    "messages": [
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": conversation["user"]},
                        {"role": "assistant", "content": conversation["assistant"]}
                    ]
                }
                
                examples.append(example)
                
            except json.JSONDecodeError:
                print(f"⚠️  Failed to parse response for {subcategory} #{i}")
                continue
    
    return examples


def generate_walking_context(subcategory: str) -> Dict:
    """Gera contexto aleatório realista para diferentes subcategorias"""
    
    # Locais comuns em Portugal
    places = [
        "Parque Municipal", "Jardim Público", "Biblioteca", "Farmácia",
        "Supermercado", "Café", "Padaria", "Correios", "Centro de Saúde",
        "Mercado Municipal", "Centro Comercial", "Praça", "Igreja", "Junta de Freguesia"
    ]
    
    base_context = {
        "steps_today": random.randint(0, 5000),
        "step_goal": random.choice([2000, 3000, 4000, 5000, 6000, 8000]),
    }
    
    if subcategory == "direct_request":
        # Adicionar locais próximos
        n_places = random.randint(2, 5)
        selected_places = random.sample(places, n_places)
        
        base_context["nearby_places"] = [
            f"{place} ({random.randint(300, 3000)} passos, {random.randint(4, 35)} min a pé)"
            for place in selected_places
        ]
    
    elif subcategory == "low_energy":
        base_context["energy_level"] = random.choice(["baixa", "muito baixa"])
        base_context["symptom"] = random.choice([
            "cansaço", "má noite de sono", "falta de ar leve", "dia difícil"
        ])
    
    elif subcategory == "weather":
        base_context["weather"] = random.choice([
            "chuva forte", "muito calor (35°C)", "muito frio (5°C)",
            "vento forte", "neve", "granizo"
        ])
        base_context["time"] = f"{random.randint(8, 20)}:00"
    
    elif subcategory == "multiple_destinations":
        n_places = random.randint(3, 6)
        base_context["nearby_places"] = [
            f"{random.choice(places)} ({random.randint(200, 2000)} passos, {random.randint(3, 25)} min)"
            for _ in range(n_places)
        ]
    
    elif subcategory == "progression":
        base_context["days_active"] = random.randint(1, 30)
        base_context["is_beginner"] = random.choice([True, False])
    
    return base_context


def generate_goal_adjustment_examples(n: int = 300) -> List[Dict]:
    """Gera exemplos de ajuste de metas"""
    
    examples = []
    
    subcategories = {
        "increase_goal": 0.33,      # 100 exemplos
        "decrease_goal": 0.33,      # 100 exemplos
        "maintain_goal": 0.20,      # 60 exemplos
        "celebrate_milestone": 0.14 # 40 exemplos
    }
    
    for subcategory, proportion in subcategories.items():
        n_examples = int(n * proportion)
        
        print(f"Generating {n_examples} examples for: goal/{subcategory}")
        
        for i in tqdm(range(n_examples)):
            context = generate_goal_context(subcategory)
            
            prompt = f"""Gera conversação em português de Portugal sobre ajuste de meta de passos.

Categoria: {subcategory}
Contexto: {json.dumps(context, ensure_ascii=False)}

User: Pergunta sobre mudar meta (1-2 frases)
Assistant: Resposta baseada em dados do contexto, explicando decisão (50-150 palavras)

Retorna JSON: {{"user": "...", "assistant": "..."}}
"""
            
            response = client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "Gera datasets médicos."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.8,
                max_tokens=500
            )
            
            try:
                conversation = json.loads(response.choices[0].message.content)
                examples.append({
                    "messages": [
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": conversation["user"]},
                        {"role": "assistant", "content": conversation["assistant"]}
                    ]
                })
            except:
                continue
    
    return examples


def generate_goal_context(subcategory: str) -> Dict:
    """Gera contexto para ajuste de metas"""
    
    current_goal = random.choice([2000, 3000, 4000, 5000, 6000])
    
    if subcategory == "increase_goal":
        return {
            "current_goal": current_goal,
            "avg_steps_last_7_days": int(current_goal * random.uniform(1.1, 1.3)),
            "days_exceeded_goal": random.randint(5, 7)
        }
    
    elif subcategory == "decrease_goal":
        return {
            "current_goal": current_goal,
            "recent_illness": random.choice(["gripe", "constipação", "infeção respiratória"]),
            "avg_steps_last_3_days": int(current_goal * random.uniform(0.3, 0.6))
        }
    
    elif subcategory == "maintain_goal":
        return {
            "current_goal": current_goal,
            "avg_steps_last_7_days": int(current_goal * random.uniform(0.95, 1.05)),
            "days_exceeded_goal": random.randint(3, 5)
        }
    
    elif subcategory == "celebrate_milestone":
        months_ago_goal = int(current_goal * random.uniform(0.2, 0.5))
        return {
            "current_achievement": current_goal,
            "months_ago_baseline": months_ago_goal,
            "improvement_percentage": int(((current_goal - months_ago_goal) / months_ago_goal) * 100)
        }
    
    return {}


def generate_motivation_examples(n: int = 200) -> List[Dict]:
    """Gera exemplos de motivação básica"""
    
    examples = []
    
    subcategories = {
        "difficult_day": 0.40,      # 80 exemplos
        "positive_reinforcement": 0.35,  # 70 exemplos
        "streak_celebration": 0.15,      # 30 exemplos
        "emotional_support": 0.10        # 20 exemplos
    }
    
    for subcategory, proportion in subcategories.items():
        n_examples = int(n * proportion)
        
        print(f"Generating {n_examples} examples for: motivation/{subcategory}")
        
        for i in tqdm(range(n_examples)):
            context = generate_motivation_context(subcategory)
            
            prompt = f"""Gera conversação motivacional em português de Portugal.

Categoria: {subcategory}
Contexto: {json.dumps(context, ensure_ascii=False)}

Requisitos:
- User: Expressa sentimento/situação
- Assistant: Resposta empática, encorajadora, realista (50-120 palavras)
- Tom: Acolhedor, nunca condescendente

JSON: {{"user": "...", "assistant": "..."}}
"""
            
            response = client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "Gera datasets médicos motivacionais."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.9,
                max_tokens=400
            )
            
            try:
                conversation = json.loads(response.choices[0].message.content)
                examples.append({
                    "messages": [
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": conversation["user"]},
                        {"role": "assistant", "content": conversation["assistant"]}
                    ]
                })
            except:
                continue
    
    return examples


def generate_motivation_context(subcategory: str) -> Dict:
    """Gera contexto para motivação"""
    
    if subcategory == "difficult_day":
        return {
            "steps_today": random.randint(0, 1500),
            "step_goal": random.choice([3000, 4000, 5000]),
            "feeling": random.choice(["frustrado", "desanimado", "cansado"])
        }
    
    elif subcategory == "positive_reinforcement":
        goal = random.choice([2000, 3000, 4000])
        return {
            "steps_today": int(goal * random.uniform(0.7, 0.95)),
            "step_goal": goal,
            "time": f"{random.randint(16, 21)}:00"
        }
    
    elif subcategory == "streak_celebration":
        return {
            "consecutive_days": random.randint(7, 30),
            "milestone": random.choice(["7_days", "14_days", "30_days"])
        }
    
    elif subcategory == "emotional_support":
        return {
            "emotion": random.choice(["frustração", "ansiedade", "desesperança"]),
            "trigger": random.choice([
                "doença crónica", "progressão lenta", "dia muito difícil"
            ])
        }
    
    return {}


def save_dataset(examples: List[Dict], filename: str):
    """Salva dataset em formato JSONL"""
    
    with open(filename, 'w', encoding='utf-8') as f:
        for example in examples:
            f.write(json.dumps(example, ensure_ascii=False) + '\n')
    
    print(f"✅ Saved {len(examples)} examples to {filename}")


def main():
    """Função principal"""
    
    print("🚀 Starting MVP Dataset Generation...")
    print(f"Target: 1000 examples total")
    print(f"  - Walking Recommendations: 500")
    print(f"  - Goal Adjustment: 300")
    print(f"  - Basic Motivation: 200")
    print()
    
    all_examples = []
    
    # Gerar cada categoria
    print("📊 Category 1/3: Walking Recommendations")
    walking_examples = generate_walking_recommendation_examples(500)
    all_examples.extend(walking_examples)
    print(f"Generated {len(walking_examples)} walking examples\n")
    
    print("📊 Category 2/3: Goal Adjustment")
    goal_examples = generate_goal_adjustment_examples(300)
    all_examples.extend(goal_examples)
    print(f"Generated {len(goal_examples)} goal examples\n")
    
    print("📊 Category 3/3: Basic Motivation")
    motivation_examples = generate_motivation_examples(200)
    all_examples.extend(motivation_examples)
    print(f"Generated {len(motivation_examples)} motivation examples\n")
    
    # Shuffle para misturar categorias
    random.shuffle(all_examples)
    
    # Salvar
    output_file = "mvp_dataset_1000.jsonl"
    save_dataset(all_examples, output_file)
    
    print(f"""
✅ Dataset Generation Complete!

📊 Statistics:
  - Total examples: {len(all_examples)}
  - File: {output_file}
  - Size: {os.path.getsize(output_file) / 1024 / 1024:.2f} MB

🎯 Next Steps:
  1. Review examples manually: head -20 {output_file}
  2. Validate with physiotherapist
  3. Upload to Hugging Face or Google Colab
  4. Run fine-tuning script
""")


if __name__ == "__main__":
    main()
```

---

## 📝 Como Usar o Script

### **1. Instalar Dependências**

```bash
pip install openai tqdm
```

### **2. Configurar API Key**

```bash
export OPENAI_API_KEY="sk-your-key-here"
```

### **3. Executar Geração**

```bash
python generate_mvp_dataset.py
```

### **4. Output Esperado**

```
mvp_dataset_1000.jsonl (cada linha é um exemplo)
```

### **5. Validar Dataset**

```bash
# Ver primeiros 5 exemplos
head -5 mvp_dataset_1000.jsonl | jq

# Contar total de linhas
wc -l mvp_dataset_1000.jsonl

# Validar formato JSON
jq empty mvp_dataset_1000.jsonl
```

---

## 🔬 Fine-Tuning com o Dataset

### **Opção A: Hugging Face (Recomendado)**

```python
from transformers import AutoModelForCausalLM, AutoTokenizer
from datasets import load_dataset
from trl import SFTTrainer, SFTConfig

# 1. Carregar modelo base
model = AutoModelForCausalLM.from_pretrained("google/gemma-2b-it")
tokenizer = AutoTokenizer.from_pretrained("google/gemma-2b-it")

# 2. Carregar dataset
dataset = load_dataset("json", data_files="mvp_dataset_1000.jsonl")

# 3. Formatar para Gemma chat template
def format_chat(example):
    messages = example["messages"]
    text = ""
    for msg in messages:
        if msg["role"] == "user":
            text += f"<start_of_turn>user\n{msg['content']}<end_of_turn>\n"
        elif msg["role"] == "assistant":
            text += f"<start_of_turn>model\n{msg['content']}<end_of_turn>\n"
    return {"text": text}

dataset = dataset.map(format_chat)

# 4. Training
trainer = SFTTrainer(
    model=model,
    args=SFTConfig(
        output_dir="./gemma-rehab-mvp",
        num_train_epochs=3,
        per_device_train_batch_size=2,
        learning_rate=2e-5,
        logging_steps=10,
        save_steps=100,
    ),
    train_dataset=dataset["train"],
    tokenizer=tokenizer,
)

trainer.train()
trainer.save_model("./gemma-rehab-mvp-final")
```

### **Opção B: Google Colab (Gratuito)**

```python
# Notebook Colab: https://colab.research.google.com

# 1. Upload mvp_dataset_1000.jsonl
from google.colab import files
uploaded = files.upload()

# 2. Install dependencies
!pip install transformers trl datasets accelerate

# 3. Run training (copiar código acima)

# 4. Download modelo treinado
!zip -r gemma-rehab-mvp.zip ./gemma-rehab-mvp-final
files.download('gemma-rehab-mvp.zip')
```

---

## 🎯 Estimativa de Custos

### **Geração do Dataset (GPT-4)**

```
1000 exemplos × ~400 tokens/exemplo × $0.03/1K tokens = ~$12
```

### **Fine-Tuning (Google Colab)**

```
Free tier: T4 GPU (suficiente para Gemma 2B)
Tempo: ~2-4 horas
Custo: $0 (grátis)
```

### **Total Fase 1 MVP**

```
Dataset: $12
Compute: $0
Validação médica (8h @ €50/h): €400
TOTAL: ~€412
```

---

## ✅ Checklist de Validação

Antes de fazer fine-tuning, validar manualmente 50 exemplos aleatórios:

- [ ] Português de Portugal correto (não brasileiro)
- [ ] Informação médica precisa
- [ ] Tom empático mas profissional
- [ ] Conselhos seguros (sem riscos)
- [ ] Contexto relevante mencionado
- [ ] Emojis usados apropriadamente
- [ ] Comprimento adequado (50-150 palavras)

---

## 📚 Próximos Passos

Após gerar e validar o MVP:

1. **Week 1-2:** Gerar dataset → validar com fisioterapeuta
2. **Week 3:** Fine-tune em Google Colab
3. **Week 4:** Quantizar para GGUF e testar na app
4. **Week 5-6:** Beta testing com 10 utilizadores
5. **Week 7+:** Iterar baseado em feedback

**Boa sorte! 🚀**
