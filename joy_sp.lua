local extension = Package("joy_sp")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_sp"] = "欢乐专属",
  ["joy"] = "欢乐",
  ["joysp"] = "欢乐SP",
}

local U = require "packages/utility/utility"

--几乎全新技能组的武将
--于吉 左慈 甘夫人 SP大乔 SP小乔 SP甄姬 神张辽 神典韦 神孙权 神大小乔 神华佗 神貂蝉
Fk:loadTranslationTable{
  ["joy__yuji"] = "于吉",
  ["joy__guhuo"] = "蛊惑",
  [":joy__guhuo"] = "每回合限一次，当你使用伤害牌结算后，你摸一张牌；若此牌未造成伤害，则将此牌移出游戏，本回合结束后获得之。",
}

Fk:loadTranslationTable{
  ["joy__zuoci"] = "左慈",
  ["joy__shendao"] = "神道",
  [":joy__shendao"] = "你的判定牌生效前，你可以将判定结果修改为任意花色。",
  ["joy__xinsheng"] = "新生",
  [":joy__xinsheng"] = "当你受到伤害后，你可以亮出牌堆顶三张牌，然后获得其中花色不同的牌各一张。",
}

local ganfuren = General(extension, "joy__ganfuren", "shu", 3, 3, General.Female)
local joy__shushen = fk.CreateTriggerSkill{
  name = "joy__shushen",
  anim_type = "support",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__shushen-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if not player.dead then
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    end
    return true
  end,
}
local joy__shushen_trigger = fk.CreateTriggerSkill{
  name = "#joy__shushen_trigger",
  mute = true,
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("joy__shushen")
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.num do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player),
      function(p) return p.id end), 1, 1, "#joy__shushen-choose", "joy__shushen", true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("joy__shushen")
    room:notifySkillInvoked(player, "joy__shushen")
    room:getPlayerById(self.cost_data):drawCards(1, "joy__shushen")
  end,
}
local joy__huangsi = fk.CreateTriggerSkill{
  name = "joy__huangsi",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__huangsi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum()
    room:recover({
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    player:throwAllCards("h")
    if player.dead then return end
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, function(p)
      return p.id end), 1, 1, "#joy__huangsi-choose:::"..(n + 2), self.name, true)
    if #to > 0 then
      room:getPlayerById(to[1]):drawCards(n + 1, self.name)
    end
  end,
}
joy__shushen:addRelatedSkill(joy__shushen_trigger)
ganfuren:addSkill(joy__shushen)
ganfuren:addSkill(joy__huangsi)
Fk:loadTranslationTable{
  ["joy__ganfuren"] = "甘夫人",
  ["joy__shushen"] = "淑慎",
  [":joy__shushen"] = "当一名角色受到伤害时，你可以失去1点体力并防止此伤害，然后你与其各摸一张牌；当你回复1点体力后，你可以令一名其他角色摸一张牌。",
  ["joy__huangsi"] = "皇思",
  [":joy__huangsi"] = "限定技，当你处于濒死状态时，你可以回复体力至1并弃置所有手牌，然后你可以令一名角色摸X+2张牌（X为你弃置的牌数）。",
  ["#joy__shushen-invoke"] = "淑慎：你可以失去1点体力防止 %dest 受到的伤害，然后你与其各摸一张牌",
  ["#joy__shushen-choose"] = "淑慎：你可以令一名其他角色摸一张牌",
  ["#joy__huangsi-invoke"] = "皇思：你可以回复体力至1，弃置所有手牌",
  ["#joy__huangsi-choose"] = "皇思：你可以令一名角色摸%arg张牌",
}

local sp__daqiao = General(extension, "joysp__daqiao", "wu", 3, 3, General.Female)
local joy__yanxiao = fk.CreateActiveSkill{
  name = "joy__yanxiao",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#joy__yanxiao",
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):hasDelayedTrick("yanxiao_trick")
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:cloneCard("yanxiao_trick")
    card:addSubcards(effect.cards)
    target:addVirtualEquip(card)
    room:moveCardTo(card, Card.PlayerJudge, target, fk.ReasonJustMove, self.name)
  end,
}
local joy__yanxiao_trigger = fk.CreateTriggerSkill{
  name = "#joy__yanxiao_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Judge and player:hasDelayedTrick("yanxiao_trick")
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("joy__yanxiao")
    room:notifySkillInvoked(player, "joy__yanxiao")
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getCardIds("j"))
    room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    local judge = {
      who = player,
      reason = "joy__yanxiao",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      player:drawCards(1, "joy__yanxiao")
    elseif judge.card.color == Card.Black then
      room:setPlayerMark(player, "joy__yanxiao-turn", 1)
    end
  end,
}
local joy__yanxiao_targetmod = fk.CreateTargetModSkill{
  name = "#joy__yanxiao_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("joy__yanxiao-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
    return 0
  end,
}
local joy__guose = fk.CreateTriggerSkill{
  name = "joy__guose",
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.extra_data and move.extra_data.joy__guose then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id and move.extra_data and move.extra_data.joy__guose then
        n = n + move.extra_data.joy__guose
      end
    end
    player:drawCards(n, self.name)
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and Fk:getCardById(info.cardId).suit == Card.Diamond then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        local n = 0
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and Fk:getCardById(info.cardId).suit == Card.Diamond then
            n = n + 1
          end
        end
        if n > 0 then
          move.extra_data = move.extra_data or {}
          move.extra_data.joy__guose = n
        end
      end
    end
  end,
}
local joy__anxian = fk.CreateTriggerSkill{
  name = "joy__anxian",
  mute = true,
  events = {fk.TargetSpecifying, fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" then
      if event == fk.TargetSpecifying then
        return not table.contains(data.card.skillNames, self.name)
      else
        return not player:isNude()
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.TargetSpecifying then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        local p = player.room:getPlayerById(id)
        if not player.dead and player:hasSkill(self.name) and not p.dead and not p:isKongcheng() then
          self:doCost(event, target, player, id)
        end
      end
    else
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecifying then
      return room:askForSkillInvoke(player, self.name, nil, "#joy__anxian1-invoke::"..data)
    else
      local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".",
        "#joy__anxian2-invoke::"..data.from..":"..data.card:toLogString(), true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecifying then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "control")
      local p = room:getPlayerById(data)
      if not p:isKongcheng() then
        room:askForDiscard(p, 1, 1, false, self.name, false)
      end
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "defensive")
      table.insertIfNeed(data.nullifiedTargets, player.id)
      local suit = Fk:getCardById(self.cost_data[1]).suit
      room:throwCard(self.cost_data, self.name, player, player)
      local from = room:getPlayerById(data.from)
      if not from.dead then
        from:drawCards(1, self.name)
      end
      if not player.dead and not from.dead and suit == Card.Diamond then
        room:useVirtualCard("slash", nil, player, from, self.name, true)
      end
    end
  end
}
joy__yanxiao:addRelatedSkill(joy__yanxiao_trigger)
joy__yanxiao:addRelatedSkill(joy__yanxiao_targetmod)
sp__daqiao:addSkill(joy__yanxiao)
sp__daqiao:addSkill(joy__guose)
sp__daqiao:addSkill(joy__anxian)
Fk:loadTranslationTable{
  ["joysp__daqiao"] = "大乔",
  ["joy__yanxiao"] = "言笑",
  [":joy__yanxiao"] = "出牌阶段，你可以将一张<font color='red'>♦</font>牌置于一名角色的判定区内，判定区有“言笑”牌的角色下个判定阶段开始时，"..
  "获得其判定区内所有牌并进行一次判定，若结果为：红色，其摸一张牌；黑色，本回合出牌阶段使用【杀】次数上限+1。",
  ["joy__guose"] = "国色",
  [":joy__guose"] = "锁定技，当你失去一张<font color='red'>♦</font>牌后，你摸一张牌。",
  ["joy__anxian"] = "安娴",
  [":joy__anxian"] = "当你不以此法使用【杀】指定目标时，你可以令目标弃置一张手牌；当你成为【杀】的目标时，你可以弃置一张牌令之无效，然后使用者"..
  "摸一张牌，若你弃置的是<font color='red'>♦</font>牌，你视为对其使用一张【杀】。",
  ["#joy__yanxiao"] = "言笑：你可以将一张<font color='red'>♦</font>牌置于一名角色的判定区内，其判定阶段开始时获得判定区内所有牌",
  ["#joy__anxian1-invoke"] = "安娴：你可以令 %dest 弃置一张手牌",
  ["#joy__anxian2-invoke"] = "安娴：你可以弃置一张牌令 %dest 对你使用的%arg无效，若弃置的是<font color='red'>♦</font>，你视为对其使用【杀】",
}

local sp__xiaoqiao = General(extension, "joysp__xiaoqiao", "wu", 3, 3, General.Female)
local joy__xingwu = fk.CreateActiveSkill{
  name = "joy__xingwu",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  prompt = "#joy__xingwu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    player:turnOver()
    if player.dead then return end
    if #target:getCardIds("e") > 0 then
      local id = room:askForCardChosen(player, target, "e", self.name)
      room:throwCard({id}, self.name, target, player)
    end
    if target.dead then return end
    local n = target.gender == General.Male and 2 or 1
    room:damage{
      from = player,
      to = target,
      damage = n,
      skillName = self.name,
    }
  end,
}
local joy__luoyan = fk.CreateTriggerSkill{
  name = "joy__luoyan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.name == "joy__xingwu"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    for _, s in ipairs({"joyex__tianxiang", "joyex__hongyan"}) do
      if not player:hasSkill(s, true) then
        table.insert(skills, s)
      end
    end
    if #skills == 0 then return end
    room:setPlayerMark(player, "joy__luoyan", skills)
    room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("joy__luoyan") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local skills = player:getMark("joy__luoyan")
    room:setPlayerMark(player, "joy__luoyan", 0)
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
  end,
}
local joy__huimou = fk.CreateTriggerSkill{
  name = "joy__huimou",
  anim_type = "support",
  events = {fk.CardUseFinished, fk.CardRespondFinished, fk.SkillEffect},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.NotActive and
      table.find(player.room.alive_players, function(p) return not p.faceup end) then
      if event == fk.SkillEffect then
        return data.name == "joyex__tianxiang"
      else
        return data.card.suit == Card.Heart
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
      return not p.faceup end), function(p) return p.id end),
      1, 1, "#joy__huimou-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(self.cost_data):turnOver()
  end,
}
sp__xiaoqiao:addSkill(joy__xingwu)
sp__xiaoqiao:addSkill(joy__luoyan)
sp__xiaoqiao:addSkill(joy__huimou)
Fk:loadTranslationTable{
  ["joysp__xiaoqiao"] = "小乔",
  ["joy__xingwu"] = "星舞",
  [":joy__xingwu"] = "出牌阶段限一次，你可以弃置一张手牌并翻面，弃置一名其他角色装备区内一张牌，然后对其造成1点伤害；若其为男性角色，则改为2点。",
  ["joy__luoyan"] = "落雁",
  [":joy__luoyan"] = "锁定技，当你发动〖星舞〗后，直到你下个出牌阶段开始时，你获得〖天香〗和〖红颜〗。",
  ["joy__huimou"] = "回眸",
  [":joy__huimou"] = "当你于回合外使用或打出<font color='red'>♥</font>牌后，或当你发动〖天香〗时，你可以令一名武将牌背面朝上的角色翻至正面。",
  ["#joy__xingwu"] = "星舞：弃置一张手牌并翻面，弃置一名其他角色装备区内一张牌，对其造成伤害",
  ["#joy__huimou-choose"] = "回眸：你可以令一名武将牌背面朝上的角色翻至正面",
}

local sp__zhenji = General(extension, "joysp__zhenji", "qun", 3, 3, General.Female)
local joy__jinghong = fk.CreateTriggerSkill{
  name = "joy__jinghong",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() end), function(p) return p.id end)
    local n = math.min(#room.alive_players - 1, 4)
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#joy__jinghong-choose:::"..n, self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead and not p:isKongcheng() then
        local card = table.random(p:getCardIds("h"))
        p:showCards(card)
        if Fk:getCardById(card).color == Card.Black and (room:getCardOwner(card) == p or room:getCardArea(card) == Card.DiscardPile) then
          room:obtainCard(player, card, true, fk.ReasonPrey)
          if room:getCardOwner(card) == player and room:getCardArea(card) == Card.PlayerHand then
            room:setCardMark(Fk:getCardById(card), "@@joy__jinghong-inhand", 1)
          end
        elseif Fk:getCardById(card).color == Card.Red and room:getCardOwner(card) == p and room:getCardArea(card) == Card.PlayerHand then
          room:throwCard({card}, self.name, p, p)
        end
      end
    end
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@joy__jinghong-inhand", 0)
    end
  end,
}
local joy__jinghong_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__jinghong_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@joy__jinghong-inhand") > 0
  end,
}
local joy__luoshen = fk.CreateViewAsSkill{
  name = "joy__luoshen",
  anim_type = "defensive",
  pattern = "jink",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("jink")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
}
local nya__luoshen_trigger = fk.CreateTriggerSkill{
  name = "#nya__luoshen_trigger",
  mute = true,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("joy__luoshen") and table.contains(data.card.skillNames, "joy__luoshen") and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "joy__luoshen")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    while true do
      local judge = {
        who = player,
        reason = "joy__luoshen",
        pattern = ".|.|spade,club",
        skipDrop = true,
      }
      room:judge(judge)
      table.insert(cards, judge.card)
      if judge.card.color ~= Card.Black or not room:askForSkillInvoke(player, "joy__luoshen") then
        break
      end
    end
    cards = table.filter(cards, function(card) return room:getCardArea(card.id) == Card.Processing end)
    if #cards == 0 then return end
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(table.map(cards, function(card) return card:getEffectiveId() end))
    room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
  end,
}
joy__jinghong:addRelatedSkill(joy__jinghong_maxcards)
joy__luoshen:addRelatedSkill(nya__luoshen_trigger)
sp__zhenji:addSkill(joy__jinghong)
sp__zhenji:addSkill(joy__luoshen)
Fk:loadTranslationTable{
  ["joysp__zhenji"] = "甄姬",
  ["joy__jinghong"] = "惊鸿",
  [":joy__jinghong"] = "准备阶段，你可以选择至多X名其他角色（X为存活角色数-1，至多为4），依次随机展示其一张手牌，若为：黑色，你获得之，"..
  "且本回合不计入手牌上限；红色，其弃置之。",
  ["joy__luoshen"] = "洛神",
  [":joy__luoshen"] = "你可以将一张黑色牌当【闪】使用或打出；每轮限一次，你以此法使用或打出【闪】时，你可以判定，若结果为：黑色，你获得之，"..
  "然后你可以重复此流程；红色，你获得之。",
  ["#joy__jinghong-choose"] = "惊鸿：令至多%arg名其他角色依次随机展示一张手牌，若为黑色你获得之，若为红色其弃置之",
  ["@@joy__jinghong-inhand"] = "惊鸿",
}

local goddiaochan = General(extension, "joy__goddiaochan", "god", 3, 3, General.Female)
local joy__meihun = fk.CreateTriggerSkill{
  name = "joy__meihun",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Finish
      elseif event == fk.TargetConfirmed then
        return data.card.trueName == "slash" and player:getMark("joy__meihun-turn") == 0
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      player.room:setPlayerMark(player, "joy__meihun-turn", 1)
    end
    self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#joy__meihun-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(player, {"log_spade", "log_heart", "log_club", "log_diamond"}, self.name, "#joy__meihun-choice::"..to.id)
    local cards = {}
    for _, id in ipairs(to:getCardIds("he")) do
      if Fk:getCardById(id):getSuitString(true) == choice then
        table.insert(cards, id)
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, to.id)
    elseif not to:isKongcheng() then
      local id = room:askForCardChosen(player, to, { card_data = { { "$Hand", to:getCardIds(Player.Hand) }  } }, self.name)
      room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
    end
  end,
}
local joy__huoxin = fk.CreateActiveSkill{
  name = "joy__huoxin",
  anim_type = "control",
  card_num = 1,
  target_num = 2,
  prompt = "#joy__huoxin",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected < 2 and #selected_cards == 1 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng() then
      if to_select == Self.id then
        if Fk:currentRoom():getCardArea(selected_cards[1]) == Player.Hand then
          return Self:getHandcardNum() > 1
        else
          return not Self:isKongcheng()
        end
      else
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local targets = table.map(effect.tos, function(id) return room:getPlayerById(id) end)
    local pindian = targets[1]:pindian({targets[2]}, self.name)
    if player.dead then return end
    local losers = {}
    if pindian.results[targets[2].id].winner == targets[1] then
      losers = {targets[2]}
    elseif pindian.results[targets[2].id].winner == targets[2] then
      losers = {targets[1]}
    else
      losers = targets
    end
    local suits = {"", "spade", "heart", "club", "diamond"}
    local choices = table.map(suits, function(s) return Fk:translate("log_"..s) end)
    choices[1] = "Cancel"
    local choice = room:askForChoice(player, choices, self.name, "#joy__huoxin-choice")
    if choice ~= "Cancel" then
      local suit = suits[table.indexOf(choices, choice)]
      for _, p in ipairs(losers) do
        if player.dead then return end
        if not p.dead then
          room:doIndicate(player.id, {p.id})
          if table.find(p:getCardIds("he"), function(id) return Fk:getCardById(id):getSuitString() == suit end) then
            local choice2 = room:askForChoice(player, {"joy__huoxin_prey:::"..choice, "joy__huoxin_mark"}, self.name,
              "#joy__huoxin2-choice::"..p.id)
            if choice2[13] == "p" then
              local dummy = Fk:cloneCard("dilu")
              for _, id in ipairs(p:getCardIds("he")) do
                if Fk:getCardById(id):getSuitString() == suit then
                  dummy:addSubcard(id)
                end
              end
              if #dummy.subcards > 0 then
                room:obtainCard(player, dummy, false, fk.ReasonGive)
              end
            else
              room:setPlayerMark(p, "@joy__huoxin-turn", choice)
            end
          else
            room:setPlayerMark(p, "@joy__huoxin-turn", choice)
          end
        end
      end
    end
  end,
}
local joy__huoxin_prohibit = fk.CreateProhibitSkill{
  name = "#joy__huoxin_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@joy__huoxin-turn") ~= 0 and player:getMark("@joy__huoxin-turn") == card:getSuitString(true)
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@joy__huoxin-turn") ~= 0 and player:getMark("@joy__huoxin-turn") == card:getSuitString(true)
  end,
}
joy__huoxin:addRelatedSkill(joy__huoxin_prohibit)
goddiaochan:addSkill(joy__meihun)
goddiaochan:addSkill(joy__huoxin)
Fk:loadTranslationTable{
  ["joy__goddiaochan"] = "神貂蝉",
  ["joy__meihun"] = "魅魂",
  [":joy__meihun"] = "结束阶段或每回合你首次成为【杀】的目标后，你可以声明一种花色，令一名其他角色交给你所有此花色的牌，若其没有，则你观看"..
  "其手牌并获得其中一张。",
  ["joy__huoxin"] = "惑心",
  [":joy__huoxin"] = "出牌阶段限一次，你可以弃置一张牌令两名角色拼点，然后你可以声明一种花色，令没赢的角色交给你此花色的所有牌"..
  "或获得此花色的“魅惑”标记。有“魅惑”的角色不能使用或打出对应花色的牌直到回合结束。",
  ["#joy__meihun-choose"] = "魅魂：你可以令一名其他角色交给你指定花色的所有牌，或你观看并获得其一张手牌",
  ["#joy__meihun-choice"] = "魅魂：选择令 %dest 交给你的花色",
  ["#joy__huoxin"] = "惑心：弃置一张牌令两名角色拼点，没赢的角色交给你声明花色的牌或获得“魅惑”标记",
  ["#joy__huoxin-choice"] = "惑心：你可以声明一种花色，令没赢的角色交给你此花色的牌或获得“魅惑”标记",
  ["#joy__huoxin2-choice"] = "惑心：选择对 %dest 执行的一项",
  ["joy__huoxin_prey"] = "令其交给你所有%arg牌",
  ["joy__huoxin_mark"] = "令其获得“魅惑”标记",
  ["@joy__huoxin-turn"] = "魅惑",
}

Fk:loadTranslationTable{
  ["joy__libai"] = "李白",
  ["joy__shixian"] = "诗仙",
  [":joy__shixian"] = "锁定技，准备阶段，你清除已有的诗篇并亮出牌堆顶四张牌，根据花色创作对应的诗篇：<font color='red'>♥</font>《静夜思》；"..
  "<font color='red'>♦</font>《行路难》；♠《侠客行》；♣《将进酒》。然后你获得其中重复花色的牌。",
  ["jingyesi"] = "静夜思",
  [":jingyesi"] = "出牌阶段结束时，你可以观看牌堆顶一张牌，然后可以使用此牌；弃牌阶段结束时，你获得牌堆底的一张牌。",
  ["xinglunan"] = "行路难",
  [":xinglunan"] = "锁定技，你的回合外，当其他角色对你使用【杀】结算后，直到你的回合开始，其他角色计算与你的距离+1。",
  ["xiakexing"] = "侠客行",
  [":xiakexing"] = "当你使用牌名中有“剑”的武器时，你视为使用一张【万箭齐发】；当你使用【杀】造成伤害后，若你装备了武器，你可以与其拼点："..
  "若你赢，其减1点体力上限；若你没赢，则弃置你装备区内的武器。",
  ["qiangjinjiu"] = "将进酒",
  [":qiangjinjiu"] = "其他角色准备阶段，你可以弃置一张手牌并选择一项：1.弃置其装备区内所有的装备，令其从牌堆中获得一张【酒】；"..
  "2.获得其手牌中所有【酒】，若其手牌中没有【酒】，则改为获得其一张牌。",
}

local joy__change = General(extension, "joy__change", "god", 1, 4, General.Female)
local joy__daoyao = fk.CreateActiveSkill{
  name = "joy__daoyao",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and
      not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local ids = room:getCardsFromPileByRule("peach")
    if #ids > 0 then
      room:obtainCard(player, ids[1], false, fk.ReasonPrey)
    end
    if not player.dead then
      player:drawCards(3 - #ids, self.name)
    end
  end,
}
joy__change:addSkill(joy__daoyao)
local joy__benyue = fk.CreateTriggerSkill{
  name = "joy__benyue",
  frequency = Skill.Wake,
  events = {fk.HpRecover, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      if event == fk.HpRecover then
        return target == player
      else
        for _, move in ipairs(data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.DrawPile and Fk:getCardById(info.cardId).name == "peach" then
                return true
              end
            end
          end
        end
      end
    end
  end,
  can_wake = function(self, event, target, player, data)
    if event == fk.HpRecover then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[1]
        if e.data[1] == player and e.data[3] == "recover" then
          n = n + e.data[2]
        end
      end, Player.HistoryGame)
      return n > 2
    else
      return #table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).name == "peach"
      end) > 2
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.maxHp < 15 then
      room:changeMaxHp(player, 15-player.maxHp)
    end
    room:handleAddLoseSkills(player, "joy__guanghan")
  end,
}
joy__change:addSkill(joy__benyue)
local joy__guanghan = fk.CreateTriggerSkill{
  name = "joy__guanghan",
  anim_type = "offensive",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      return data.extra_data and table.find(data.extra_data.joy__guanghan or {}, function (pid)
        return pid ~= player.id and not player.room:getPlayerById(pid).dead
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, pid in ipairs(data.extra_data.joy__guanghan) do
      local p = room:getPlayerById(pid)
      if pid ~= player.id and not p.dead then
        if p:isKongcheng() or #room:askForDiscard(p, 1, 1, false, self.name, true, ".", "#joy__guanghan-discard:::"..data.damage) == 0 then
          room:loseHp(p, data.damage, self.name)
        end
      end
    end
  end,

  refresh_events = {fk.BeforeHpChanged},
  can_refresh = function(self, event, target, player, data)
    return data.damageEvent and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local damage = data.damageEvent
    damage.extra_data = damage.extra_data or {}
    local list = {}
    for _, p in ipairs(player.room:getAlivePlayers()) do
      if target:getNextAlive() == p or p:getNextAlive() == target then
        table.insertIfNeed(list, p.id)
      end
    end
    damage.extra_data.joy__guanghan = list
  end,
}
joy__change:addRelatedSkill(joy__guanghan)
Fk:loadTranslationTable{
  ["joy__change"] = "嫦娥",
  ["#joy__change"] = "广寒仙子",
  
  ["joy__daoyao"] = "捣药",
  [":joy__daoyao"] = "出牌阶段限一次，你可以弃置一张手牌，从牌堆获得一张【桃】并摸两张牌，若牌堆没有【桃】，改为摸三张牌。",

  ["joy__benyue"] = "奔月",
  [":joy__benyue"] = "觉醒技，当你摸到【桃】后若你有至少三张【桃】，或你累计回复3点体力后，你将体力上限增加至15，并获得技能〖广寒〗。",

  ["joy__guanghan"] = "广寒",
  [":joy__guanghan"] = "锁定技，当一名角色受到伤害后，与其相邻的其他角色需弃置一张手牌，否则失去等量体力。",
  ["#joy__guanghan-discard"] = "广寒：你需弃置一张手牌，否则失去 %arg 点体力",

  ["$joy__daoyao1"] = "入河蟾不没，捣药兔长生！",
  ["$joy__daoyao2"] = "转空轧軏冰轮响，捣药叮当玉杵鸣！",
  ["$joy__benyue1"] = "一入月宫去，千秋闭峨眉。",
  ["$joy__benyue2"] = "纵令奔月成仙去，且作行云入梦来。",
  ["$joy__guanghan1"] = "银河无声月宫冷，思念如影伴孤灯。",
  ["$joy__guanghan2"] = "月宫清冷人独立，寒梦纷飞思绪深。",
}

local joy__nvwa = General(extension, "joy__nvwa", "god", 69, 159, General.Female)
local joy__butian = fk.CreateTriggerSkill{
  name = "joy__butian",
  frequency = Skill.Compulsory,
  events = { fk.DamageCaused , fk.DamageInflicted, fk.RoundEnd, fk.HpChanged, fk.MaxHpChanged, fk.GameStart, fk.EventAcquireSkill},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.DamageCaused then
      return player:getLostHp() > 4 and target == player and data.to ~= player
    elseif event == fk.DamageInflicted then
      return player:getLostHp() > 4 and target == player
    elseif event == fk.RoundEnd then
      return player:getLostHp() > 4
    elseif player.maxHp == player.hp then
      if event == fk.GameStart then return true end
      if event == fk.EventAcquireSkill then return data == self and target == player and player.room:getTag("RoundCount") end
      return target == player
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getLostHp() // 5
    if event == fk.DamageCaused then
      room:recover { num = x, skillName = self.name, who = player, recoverBy = player}
    elseif event == fk.DamageInflicted or event == fk.RoundEnd then
      room:loseHp(player, x, self.name)
    else
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p.dead then
          room:killPlayer({ who = p.id })
        end
      end
    end
  end
}
joy__nvwa:addSkill(joy__butian)
local joy__lianshi = fk.CreateTriggerSkill{
  name = "joy__lianshi",
  frequency = Skill.Compulsory,
  events = { fk.AfterCardsMove },
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local mark = U.getMark(player, "@joy__lianshi")
      local suits, num = {}, 0
      for _, move in ipairs(data) do
        if move.from == player.id and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResonpse or move.moveReason == fk.ReasonDiscard) then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card.suit ~= Card.NoSuit and not table.contains(mark, card:getSuitString(true)) and (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerHand) then
              num = math.max(num, card.number)
              table.insertIfNeed(suits, card:getSuitString(true))
            end
          end
        end
      end
      if #suits > 0 then
        self.cost_data = {suits, num}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits, num = table.unpack(self.cost_data)
    local mark = U.getMark(player, "@joy__lianshi")
    table.insertTable(mark, suits)
    room:setPlayerMark(player, "@joy__lianshi", mark)
    if #mark == 4 then
      player:drawCards(1, self.name)
      room:recover { num = num, skillName = self.name, who = player, recoverBy = player}
      room:setPlayerMark(player, "@joy__lianshi", 0)
    end
  end,
}
local joy__lianshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__lianshi_maxcards",
  fixed_func = function(self, player)
    if player:hasSkill(joy__lianshi) then
      return 5
    end
  end
}
joy__lianshi:addRelatedSkill(joy__lianshi_maxcards)
joy__nvwa:addSkill(joy__lianshi)
local joy__tuantu = fk.CreateActiveSkill{
  name = "joy__tuantu",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local get, map = {}, {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      map[Fk:getCardById(id).trueName] = {}
    end
    for _, id in ipairs(room.discard_pile) do
      local name = Fk:getCardById(id).trueName
      if map[name] then
        table.insert(map[name], id)
      end
    end
    for _, cards in pairs(map) do
      if #cards > 0 then
        table.insert(get, table.random(cards))
      end
    end
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    end
  end,
}
joy__nvwa:addSkill(joy__tuantu)
Fk:loadTranslationTable{
  ["joy__nvwa"] = "女娲",
  ["#joy__nvwa"] = "创世女神",
  ["joy__butian"] = "补天",
  [":joy__butian"] = "锁定技，你对其他角色造成伤害时，回复X点体力。每轮结束时，或你受到伤害时，你失去X点体力。当你体力值等于体力上限时，令所有其他角色依次死亡（X为你已损失体力的20%，向下取整）。",
  ["joy__lianshi"] = "炼石",
  [":joy__lianshi"] = "锁定技，你的手牌上限基数为5；每当你使用、打出或弃置牌时，记录此牌花色，然后若已记录四种花色，你摸一张牌并回复X点体力，然后清空花色记录（X为最后记录的花色对应的牌的点数，对应多张牌时取最高值）。",
  ["@joy__lianshi"] = "炼石",
  ["joy__tuantu"] = "抟土",
  [":joy__tuantu"] = "出牌阶段限一次，你可以从弃牌堆获得与手牌中牌名相同的牌各一张。",

  ["$joy__butian1"] = "断鳌足，以立四极！",
  ["$joy__butian2"] = "洪水涸，九州平！",
  ["$joy__lianshi1"] = "采五方，凝五色，炼石补天，定胜万难！",
  ["$joy__lianshi2"] = "五色蕴华，万物化生！",
  ["$joy__tuantu1"] = "抟黄土作人，力不暇供！",
  ["$joy__tuantu2"] = "引绳于泥中，举以为人！",
}

local joy__godzuoci = General(extension, "joy__godzuoci", "god", 3)

GetHuanPile = function (room)
  local cards = room:getTag("joy__huanshu_pile")
  if cards == nil then
    cards = {}
    -- 会忽略模式牌堆黑名单（例如忠胆英杰） so bad
    for _, id in ipairs(Fk:getAllCardIds()) do
      local c = Fk:getCardById(id, true)
      if not c.is_derived then
        local card = room:printCard(c.name, c.suit, c.number)
        room:setCardMark(card, "@@joy__huanshu_card", 1)
        table.insert(cards, card.id)
      end
    end
    table.shuffle(cards)
    room:setTag("joy__huanshu_pile", cards)
  end
  local temp = table.filter(cards, function(id) return room:getCardArea(id) == Card.Void end)
  return temp
end

---@param player ServerPlayer
GetHuanCard = function (player, n, skillName)
  local room = player.room
  if player.dead then return end
  local max_num = 2 * player.maxHp
  local has_num = #table.filter(player.player_cards[Player.Hand], function (id)
    return Fk:getCardById(id):getMark("@@joy__huanshu_card") ~= 0
  end)
  local get_num  = math.max(0, math.min(n, max_num - has_num))
  local draw_num = n - get_num
  if get_num > 0 then
    local pile = GetHuanPile(room)
    if #pile > 0 then
      room:moveCardTo(table.random(pile, get_num), Card.PlayerHand, player, fk.ReasonPrey, skillName)
    end
  end
  if not player.dead and draw_num > 0 then
    player:drawCards(draw_num, skillName)
  end
end

local joy__huanshu = fk.CreateTriggerSkill{
  name = "joy__huanshu",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.RoundStart, fk.Damaged, fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseStart then
      return target == player and player.phase == Player.Play and not player:isKongcheng()
    elseif event == fk.AfterCardsMove then
      local cards = {}
      for _, move in ipairs(data) do
        if move.to and move.to ~= player.id and move.toArea == Player.Hand then
          local to = player.room:getPlayerById(move.to)
          if not to:hasSkill(self) then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId):getMark("@@joy__huanshu_card") ~= 0 and table.contains(to.player_cards[Player.Hand], info.cardId) then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    else
      return (event == fk.RoundStart or target == player)
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local n = event == fk.Damaged and data.damage or 1
    for i = 1, n do
      if player.dead then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local cards, map = {}, {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        local c = Fk:getCardById(id)
        if c:getMark("@@joy__huanshu_card") == 1 then
          table.insert(cards, id)
          if map[c.suit] == nil then
            map[c.suit] = {id}
          else
            table.insert(map[c.suit], id)
          end
        end
      end
      if #cards == 0 then return end
      room:delay(500)
      -- 暂无不产生移动的换牌方式
      room:moveCardTo(cards, Card.Void, nil, fk.ReasonJustMove, self.name)
      if player.dead then return end
      local pile = GetHuanPile(room)
      local get = {}
      while #pile > 0 and #cards > 0 do
        local t = table.remove(pile, math.random(#pile))
        local suit = Fk:getCardById(t, true).suit
        if map[suit] and #map[suit] > 0 then
          table.insert(get, t)
          table.remove(map[suit], 1)
          table.remove(cards, 1)
        end
      end
      if #get > 0 then
        room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, self.name)
      end
    elseif event == fk.AfterCardsMove then
      room:moveCardTo(self.cost_data, Card.Void, nil, fk.ReasonJustMove, self.name)
      if not player.dead then
        player:drawCards(1, self.name)
      end
    else
      GetHuanCard (player, 2, self.name)
    end
  end,
}
local joy__huanshu_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__huanshu_maxcards",
  exclude_from = function(self, player, card)
    return player:hasSkill(joy__huanshu) and card and card:getMark("@@joy__huanshu_card") ~= 0
  end,
}
joy__huanshu:addRelatedSkill(joy__huanshu_maxcards)
joy__godzuoci:addSkill(joy__huanshu)

local joy__huanhua = fk.CreateActiveSkill{
  name = "joy__huanhua",
  card_num = 2,
  target_num = 0,
  prompt = "#joy__huanhua-prompt",
  card_filter = function(self, to_select, selected)
    if not table.contains(Self.player_cards[Player.Hand], to_select) then return false end
    local card = Fk:getCardById(to_select)
    if #selected == 0 then
      return card:getMark("@@joy__huanshu_card") == 1
    elseif #selected == 1 then
      return Fk:getCardById(selected[1]):getMark("@@joy__huanshu_card") == 1
      and card.type ~= Card.TypeEquip and card:getMark("joy__huanhua_tar-inhand") == 0
      and (card:getMark("@@joy__huanshu_card") == 0 or Self:getMark("@joy__huanjing-turn") > 0)
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) < (2 + player:getMark("@joy__huanjing-turn"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local huan_card = Fk:getCardById(effect.cards[1])
    local tar_card = Fk:getCardById(effect.cards[2])
    local get = huan_card.suit == tar_card.suit
    room:setCardMark(tar_card, "joy__huanhua_tar-inhand", 1)
    room:setCardMark(huan_card, "@@joy__huanshu_card", {tar_card.name, tar_card.suit, tar_card.number})
    Fk:filterCard(huan_card.id, player)
    if get then
      GetHuanCard (player, 1, self.name)
    end
  end,
}
local joy__huanhua_filter = fk.CreateFilterSkill{
  name = "#joy__huanhua_filter",
  card_filter = function(self, card, player)
    return type(card:getMark("@@joy__huanshu_card")) == "table" and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    local mark = card:getMark("@@joy__huanshu_card")
    local c = Fk:cloneCard(mark[1], mark[2], mark[3])
    c.skillName = "joy__huanhua"
    return c
  end,
}
joy__huanhua:addRelatedSkill(joy__huanhua_filter)
joy__godzuoci:addSkill(joy__huanhua)

local joy__huanjing = fk.CreateActiveSkill{
  name = "joy__huanjing",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  prompt = function()
    return "#joy__huanjing-prompt:::"..math.max(1, 2 * Self:getLostHp())
  end,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local x = math.max(1, 2 * player:getLostHp())
    room:addPlayerMark(player, "@joy__huanjing-turn", x)
    GetHuanCard (player, x, self.name)
  end,
}
joy__godzuoci:addSkill(joy__huanjing)

Fk:loadTranslationTable{
  ["joy__godzuoci"] = "神左慈",

  ["joy__huanshu"] = "幻术",
  [":joy__huanshu"] = "锁定技，每当你受到1点伤害后及每轮开始时，你获得两张幻术牌（幻术牌为开启牌中随机牌的复制），幻术牌不计入手牌上限且数量至多为你体力上限的两倍（若已达幻术牌上限，超出上限的部分将改为摸等量的牌）；出牌阶段开始时，手牌中所有未“幻化”的幻术牌将变换为同花色的其他牌；其他角色获得幻术牌后销毁之，然后你摸一张牌。",
  ["@@joy__huanshu_card"] = "幻术",

  ["joy__huanhua"] = "幻化",
  [":joy__huanhua"] = "每回合限两次，出牌阶段，你可以幻化手中的一张未“幻化”的幻术牌，令此牌的牌名、花色、点数变化为与你的一张未成为幻化目标的非装备手牌（除幻术牌外）一致，然后若幻化目标与原幻术牌的花色相同，你获得一张幻术牌。",
  -- 虚拟装备可不行，村了
  ["#joy__huanhua-prompt"] = "幻化：先选要被“幻化”的幻术牌，再选此幻术牌将变成的牌",
  ["#joy__huanhua_filter"] = "幻化",

  ["joy__huanjing"] = "幻境",
  [":joy__huanjing"] = "限定技，出牌阶段，你可以获得X张幻术牌，直到本回合结束：〖幻化〗发动次数上限增加X，且幻术牌可以成为“幻化”目标（X为你当前已损失体力值*2，且至少为1）。",
  ["#joy__huanjing-prompt"] = "幻境：获得 %arg 张幻术牌，“幻化”次数增加 %arg 次",
  ["@joy__huanjing-turn"] = "幻境",

  ["$joy__huanshu1"] = "穷则变，变则通，通则久。",
  ["$joy__huanshu2"] = "天动地宁，变化百灵。",
  ["$joy__huanhua1"] = "此事易耳。",
  ["$joy__huanhua2"] = "呵呵，这有何难？",
  ["$joy__huanjing1"] = "借小千世界，行无常勾魂！",
  ["$joy__huanjing2"] = "金丹九转，变化万端！",
  ["~joy__godzuoci"] = "当世荣华，不足贪……",
}

local joy__goddaxiaoqiao = General(extension, "joy__goddaxiaoqiao", "god", 4, 4, General.Female)

local joy__shuangshu = fk.CreateTriggerSkill{
  name = "joy__shuangshu",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(2)
    local get = true
    player:showCards(cards)
    for i = #cards, 1, -1 do
      local id = cards[i]
      table.insert(room.draw_pile, 1, id)
      if Fk:getCardById(id).color ~= Card.Black then
        get = false
        if Fk:getCardById(id).suit == Card.Diamond then
          room:setCardEmotion(id, "judgegood")
          room:setPlayerMark(player, "joy__shuangshu_pt-turn", 1)
        elseif Fk:getCardById(id).suit == Card.Heart then
          room:setCardEmotion(id, "judgegood")
          room:setPlayerMark(player, "joy__shuangshu_yz-turn", 1)
        end
      end
    end
    if get then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name)
    end
  end,
}
joy__goddaxiaoqiao:addSkill(joy__shuangshu)

local joy__pinting = fk.CreateTriggerSkill{
  name = "joy__pinting",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 2 + player:getMark("joy__shuangshu_pt-turn")
    local all_choices = {}
    for i = 1, 4 do
      table.insert(all_choices, "joy__pinting_choice"..i)
    end
    local choices = room:askForChoices(player, all_choices, 1, n, self.name, "#joy__pinting-choice:::"..n)
    local list = {}
    for i = 1, 4 do
      if table.contains(choices, "joy__pinting_choice"..i) then
        table.insert(list, i)
      end
    end
    room:setPlayerMark(player, "@joy__pinting_choices-phase", table.concat(list, "-"))
    if table.contains(list, 1) and #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      return e.data[1].from == player.id
    end, Player.HistoryPhase) == 0 then
      room:setPlayerMark(player, "joy__pinting_tmd-phase", 1)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("joy__pinting_tmd-phase") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "joy__pinting_tmd-phase", 0)
  end,
}
local joy__pinting_delay = fk.CreateTriggerSkill{
  name = "#joy__pinting_delay",
  events = {fk.CardUsing, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@joy__pinting_choices-phase")
    if target == player and mark ~= 0 then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 4, function(e)
        return e.data[1].from == player.id
      end, Player.HistoryPhase)
      if event == fk.CardUseFinished then
        if string.find(mark, "3") and events[3] and events[3].data[1] == data and player.room:getCardArea(data.card) == Card.Processing then
          self.cost_data = 3
          return true
        end
      else
        for _, i in ipairs({2,4}) do
          if string.find(mark, tostring(i)) and events[i] and events[i].data[1] == data then
            self.cost_data = i
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == 2 then
      room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonPrey, "joy__pinting")
    elseif self.cost_data == 3 then
      player:drawCards(2, "joy__pinting")
    else
      data.additionalEffect = (data.additionalEffect or 0) + 1
    end
  end,
}
local joy__pinting_targetmod = fk.CreateTargetModSkill{
  name = "#joy__pinting_targetmod",
  bypass_distances = function(self, player)
    return player:getMark("joy__pinting_tmd-phase") > 0
  end,
}
joy__pinting:addRelatedSkill(joy__pinting_delay)
joy__pinting:addRelatedSkill(joy__pinting_targetmod)
joy__goddaxiaoqiao:addSkill(joy__pinting)

---@param room Room
local getYizhengChoices = function (room, except)
  local choices = {}
  local map = {["weapon"] = {Card.SubtypeWeapon}, ["armor"] = {Card.SubtypeArmor},
  ["equip_horse"] = {Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide}}
  for _, p in ipairs(room.alive_players) do
    for str, sub_types in pairs(map) do
      if not table.contains(choices, str) then
        for _, s in ipairs(sub_types) do
          local id = p:getEquipment(s)
          if id and table.find(room.alive_players, function (p2) return p:canMoveCardInBoardTo(p2, id) end) then
            table.insert(choices, str)
            break
          end
        end
      end
    end
    if #choices == 3 then break end
  end
  table.removeOne(choices, except)
  return choices
end

local doYizheng = function (player, dat)
  local room = player.room
  local from = room:getPlayerById(dat.targets[1])
  local to = room:getPlayerById(dat.targets[2])
  local choice = dat.interaction
  local map = {["weapon"] = {Card.SubtypeWeapon}, ["armor"] = {Card.SubtypeArmor},
  ["equip_horse"] = {Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide}}
  local sub_types =  map[choice]
  local cards = {}
  for _, s in ipairs(sub_types) do
    local id = from:getEquipment(s)
    if id and to:getEquipment(s) == nil then
      table.insert(cards, id)
    end
  end
  if #cards == 0 then return end
  local cardId = room:askForCardChosen(player, from, { card_data = { { from.general, cards }  } }, "joy__yizhengg")
  room:moveCardTo(cardId, Card.PlayerEquip, to, fk.ReasonPut, "joy__yizhengg", nil, true, player.id)
end

local joy__yizhengg = fk.CreateTriggerSkill{
  name = "joy__yizhengg",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = getYizhengChoices(room)
    if #choices > 0 then
      local _,dat = room:askForUseActiveSkill(player, "joy__yizhengg_active", "#joy__yizhengg-move", true, {joy__yizhengg_choices = choices})
      if dat then
        self.cost_data = dat
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = self.cost_data
    doYizheng (player, dat)
    local once = true
    if player:getMark("joy__shuangshu_yz-turn") > 0 then
      local choices = getYizhengChoices(room, dat.interaction)
      if #choices > 0 then
        local _, _dat = room:askForUseActiveSkill(player, "joy__yizhengg_active", "#joy__yizhengg-move", true, {joy__yizhengg_choices = choices})
        if _dat then
          doYizheng (player, _dat)
          once = false
        end
      end
    end
    if player.dead then return end
    if once then
      if player:isWounded() then
        room:recover { num = 1, skillName = self.name, who = player, recoverBy = player}
      end
    else
      room:setPlayerMark(player, "@@joy__yizhengg", 1)
    end
  end,
}
local joy__yizhengg_active = fk.CreateActiveSkill{
  name = "joy__yizhengg_active",
  card_num = 0,
  target_num = 2,
  interaction = function(self)
    return UI.ComboBox {choices = self.joy__yizhengg_choices or {} , all_choices = {"weapon","armor","equip_horse"} }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local choice = self.interaction.data
    if not choice then return end
    local map = {["weapon"] = {Card.SubtypeWeapon}, ["armor"] = {Card.SubtypeArmor},
    ["equip_horse"] = {Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide}}
    local sub_types =  map[choice]
    local to = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return table.find(sub_types, function(s) return to:getEquipment(s) end)
    elseif #selected == 1 then
      local first = Fk:currentRoom():getPlayerById(selected[1])
      return table.find(sub_types, function(s) return first:getEquipment(s) and to:getEquipment(s) == nil end)
    end
  end,
}
local joy__yizhengg_delay = fk.CreateTriggerSkill{
  name = "#joy__yizhengg_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.dead or player:getMark("@@joy__yizhengg") == 0 then return false end
    local x = 0
    local color
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            x = x + 1
          end
        end
      end
    end
    if x > 0 then
      self.cost_data = x
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, "joy__yizhengg")
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@joy__yizhengg") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@joy__yizhengg", 0)
  end,
}
Fk:addSkill(joy__yizhengg_active)
joy__yizhengg:addRelatedSkill(joy__yizhengg_delay)
joy__goddaxiaoqiao:addSkill(joy__yizhengg)

Fk:loadTranslationTable{
  ["joy__goddaxiaoqiao"] = "神大小乔",

  ["joy__shuangshu"] = "双姝",
  [":joy__shuangshu"] = "准备阶段，你可以展示牌堆顶的2张牌，若包含：方块：本回合“娉婷”可选择的选项个数+1；红桃：本回合“移筝”可选择的选项个数+1；只有黑色牌：你获得展示的牌。",

  ["joy__pinting"] = "娉婷",
  [":joy__pinting"] = "出牌阶段开始时，你可选择以下选项中的至多两项：1、你使用的第一张牌无距离限制；2、你使用的第二张牌返还到你的手牌；3、你使用的第三张牌结算后摸两张牌；4、你使用的第四张牌额外结算一次。",
  ["joy__pinting_choice1"] = "第一张牌无距离限制",
  ["joy__pinting_choice2"] = "第二张牌返还到你的手牌",
  ["joy__pinting_choice3"] = "第三张牌结算后摸两张牌",
  ["joy__pinting_choice4"] = "第四张牌额外结算一次",
  ["@joy__pinting_choices-phase"] = "娉婷",
  ["#joy__pinting-choice"] = "娉婷：请选择至多 %arg 项",
  ["#joy__pinting_delay"] = "娉婷",

  ["joy__yizhengg"] = "移筝", -- 区别义争
  [":joy__yizhengg"] = "你的出牌阶段结束时，你可选择以下选项中的至多一项：1、移动场上的一张武器牌；2、移动场上的一张防具牌；3、移动场上的一张坐骑牌。若你以此法移动了：一张牌，回复1点体力；两张牌，直到你的下回合开始，你失去一张牌时摸一张牌。",
  ["#joy__yizhengg_delay"] = "移筝",
  ["@@joy__yizhengg"] = "移筝",
  ["joy__yizhengg_active"] = "移筝",
  ["#joy__yizhengg-move"] = "移筝：你可移动场上一张牌",
}

local godhuatuo = General(extension, "joy__godhuatuo", "god", 1)

local joy__jishi = fk.CreateTriggerSkill{
  name = "joy__jishi",
  anim_type = "support",
  events = {fk.GameStart, fk.AfterCardsMove, fk.EnterDying},
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EnterDying then
      return player:getMark("@joy__remedy") > 0
    else
      if player:getMark("@joy__remedy") > 2 then return false end
      local n = 0
      if event == fk.GameStart then
        n = 3
      elseif player ~= player.room.current then
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId).color == Card.Red then
                n = n + 1
              end
            end
          end
        end
      end
      if n > 0 then
        self.cost_data = n
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.EnterDying then
      return player.room:askForSkillInvoke(player, self.name, nil, "#joy__jishi-invoke:"..target.id)
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      room:removePlayerMark(player, "@joy__remedy")
      room:recover { num = 1 - target.hp, skillName = self.name, who = target, recoverBy = player }
    else
      room:setPlayerMark(player, "@joy__remedy", math.min(3, player:getMark("@joy__remedy") + self.cost_data))
    end
  end,
}
local joy__jishi_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__jishi_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(joy__jishi) then
      return 3
    end
  end,
}
joy__jishi:addRelatedSkill(joy__jishi_maxcards)
godhuatuo:addSkill(joy__jishi)

local joy__taoxian = fk.CreateViewAsSkill{
  name = "joy__taoxian",
  anim_type = "support",
  pattern = "peach",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Heart
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("peach")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local joy__taoxian_trigger = fk.CreateTriggerSkill{
  name = "#joy__taoxian_trigger",
  main_skill = joy__taoxian,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(joy__taoxian) and data.card.name == "peach"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, "joy__taoxian")
  end,
}
joy__taoxian:addRelatedSkill(joy__taoxian_trigger)
godhuatuo:addSkill(joy__taoxian)

local joy__shenzhen = fk.CreateTriggerSkill{
  name = "joy__shenzhen",
  anim_type = "control",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@joy__remedy") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local _, dat = player.room:askForUseActiveSkill(player, "joy__shenzhen_active", "#joy__shenzhen-invoke", true)
    if dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data.targets
    room:removePlayerMark(player, "@joy__remedy", #targets)
    room:sortPlayersByAction(targets)
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if self.cost_data.interaction == "recover" then
          if not p.dead and p:isWounded() then
            room:recover { num = 1, skillName = self.name, who = p, recoverBy = player }
          end
        else
          room:loseHp(p, 1, self.name)
        end
      end
    end
  end,
}
local joy__shenzhen_active = fk.CreateActiveSkill{
  name = "joy__shenzhen_active",
  card_num = 0,
  min_target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"recover", "loseHp"}}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, to_select, selected)
    return #selected < Self:getMark("@joy__remedy")
  end,
}
Fk:addSkill(joy__shenzhen_active)
godhuatuo:addSkill(joy__shenzhen)

Fk:loadTranslationTable{
  ["joy__godhuatuo"] = "神华佗",

  ["joy__jishi"] = "济世",
  [":joy__jishi"] = "游戏开始时，你获得3个“药”（至多拥有3个）。每当一名角色进入濒死状态时，你可以移去1个“药”令其回复体力至1点。当你于回合外失去红色手牌时，你获得等量“药”。你的手牌上限+3。",
  ["#joy__jishi-invoke"] = "济世：你可以移去1个“药”令 %src 回复体力至1点",
  ["@joy__remedy"] = "药",

  ["joy__taoxian"] = "桃仙",
  [":joy__taoxian"] = "你可以将一张红桃牌当【桃】使用，其他角色使用【桃】时，你摸一张牌。",
  ["#joy__taoxian_trigger"] = "桃仙",

  ["joy__shenzhen"] = "神针",
  [":joy__shenzhen"] = "回合开始时，你可以移去任意个“药”，然后选择一项：1. 令等量角色各回复1点体力；2. 令等量角色各失去1点体力。",
  ["joy__shenzhen_active"] = "神针",
  ["#joy__shenzhen-invoke"] = "神针：移去任意“药”，令等量角色回复或失去体力",
}




return extension
