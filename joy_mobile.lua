local extension = Package("joy_mobile")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_mobile"] = "欢乐-手杀改",
}

local U = require "packages/utility/utility"

-- 手杀武将上修改的武将





local joy_mouhuanggai = General(extension, "joy_mou__huanggai", "wu", 4)
local joy_mou__kurou = fk.CreateActiveSkill{
  name = "joy_mou__kurou",
  anim_type = "negative",
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:loseHp(player, 1, self.name)
    if player.dead then return end
    room:addPlayerMark(player, "@joy_mou__kurou")
    room:broadcastProperty(player, "MaxCards")
    room:changeMaxHp(player, 1)
  end
}
local joy_mou__kurou_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy_mou__kurou_maxcards",
  correct_func = function(self, player)
    return player:getMark("@joy_mou__kurou")
  end,
}
joy_mou__kurou:addRelatedSkill(joy_mou__kurou_maxcards)
local joy_mou__kurou_delay = fk.CreateTriggerSkill{
  name = "#joy_mou__kurou_delay",
  frequency = Skill.Compulsory,
  mute = true,
  events = {fk.TurnStart, fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return player == target and player:getMark("@joy_mou__kurou") > 0
    else
      return player == target and player:hasSkill(joy_mou__kurou)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local n = player:getMark("@joy_mou__kurou")
      room:setPlayerMark(player, "@joy_mou__kurou", 0)
      room:broadcastProperty(player, "MaxCards")
      room:changeMaxHp(player, -n)
    else
      room:notifySkillInvoked(player, "joy_mou__kurou", "special")
      player:setSkillUseHistory("joy_mou__kurou", 0, Player.HistoryPhase)
    end
  end,
}
joy_mou__kurou:addRelatedSkill(joy_mou__kurou_delay)
joy_mouhuanggai:addSkill(joy_mou__kurou)

local joy_mou__zhaxiang= fk.CreateTriggerSkill{
  name = "joy_mou__zhaxiang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.HpLost, fk.PreCardUse, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.HpLost then
        return true
      elseif event == fk.TurnEnd then
        return player:isWounded()
      else
        return data.card.trueName == "slash" and player:getMark("joy_mou__zhaxiang-turn") < ((player:getLostHp() + 1) // 2)
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local num = (event == fk.HpLost) and data.num or 1
    for i = 1, num do
      self:doCost(event, target, player, data)
      if player.dead then break end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.HpLost then
      player:drawCards(3)
    elseif event == fk.TurnEnd then
      local x = (player:getLostHp() + 1) // 2
      player:drawCards(x)
    else
      data.extraUse = true
      data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
    end
  end,
  
  refresh_events = {fk.CardUsing, fk.HpChanged, fk.MaxHpChanged, fk.EventAcquireSkill, fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self, true) then
      if event == fk.CardUsing then
        return target == player and data.card.trueName == "slash"
      elseif event == fk.EventAcquireSkill then
        return target == player and data == self and player.room:getTag("RoundCount")
      elseif event == fk.TurnStart then
        return true
      else
        return target == player
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "joy_mou__zhaxiang-turn")
    elseif event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "joy_mou__zhaxiang-turn", #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.from == player.id and use.card.trueName == "slash"
      end, Player.HistoryTurn))
    end
    local x = (player:getLostHp() + 1) // 2
    local used = player:getMark("joy_mou__zhaxiang-turn")
    room:setPlayerMark(player, "@joy_mou__zhaxiang-turn", used.."/"..x)
  end,
}
local joy_mou__zhaxiang_targetmod = fk.CreateTargetModSkill{
  name = "#joy_mou__zhaxiang_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and card.trueName == "slash" and player:hasSkill("joy_mou__zhaxiang")
    and player:getMark("joy_mou__zhaxiang-turn") < ((player:getLostHp() + 1) // 2)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and card.trueName == "slash" and player:hasSkill("joy_mou__zhaxiang")
    and player:getMark("joy_mou__zhaxiang-turn") < ((player:getLostHp() + 1) // 2)
  end,
}
joy_mou__zhaxiang:addRelatedSkill(joy_mou__zhaxiang_targetmod)
joy_mouhuanggai:addSkill(joy_mou__zhaxiang)
Fk:loadTranslationTable{
  ["joy_mou"] = "欢乐谋",
  ["joy_mou__huanggai"] = "谋黄盖",

  ["joy_mou__kurou"] = "苦肉",
  [":joy_mou__kurou"] = "出牌阶段限一次，你可以失去一点体力并令体力上限和手牌上限增加1点直到下回合开始。当你回复体力后，此技能视为未发动。",
  ["@joy_mou__kurou"] = "苦肉",
  ["#joy_mou__kurou_delay"] = "苦肉",

  ["joy_mou__zhaxiang"] = "诈降",
  [":joy_mou__zhaxiang"] = "锁定技，①每当你失去一点体力后，摸三张牌；②回合结束时，你摸X张牌；③每回合你使用的前X张【杀】无距离和次数限制且无法响应（X为你已损失的体力值的一半，向上取整）。",
  ["@joy_mou__zhaxiang-turn"] = "诈降",
}

local machao = General:new(extension, "joy_mou__machao", "shu", 4)
local joy__yuma = fk.CreateTriggerSkill{
  name = "joy__yuma",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and (Fk:getCardById(info.cardId).sub_type == Card.SubtypeDefensiveRide or Fk:getCardById(info.cardId).sub_type == Card.SubtypeOffensiveRide) then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and (Fk:getCardById(info.cardId).sub_type == Card.SubtypeDefensiveRide or Fk:getCardById(info.cardId).sub_type == Card.SubtypeOffensiveRide) then
            n = n + 1
          end
        end
      end
    end
    for _ = 1, n do
      if  not player:hasSkill(self) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
local joy__yuma_distance = fk.CreateDistanceSkill{
  name = "#joy__yuma_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(joy__yuma) then
      return -1
    end
  end,
}
joy__yuma:addRelatedSkill(joy__yuma_distance)
machao:addSkill(joy__yuma)
local tieji = fk.CreateTriggerSkill{
  name = "joy_mou__tieji",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to ~= player.id and
      data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke("mou__tieji", 1)
    local to = room:getPlayerById(data.to)
    data.disresponsive = true
    room:addPlayerMark(to, "@@tieji-turn")
    room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
    local choices = U.doStrategy(room, player, to, {"tieji-zhiqu","tieji-raozheng"}, {"tieji-chuzheng","tieji-huwei"}, self.name, 1)
    local win = true
    if choices[1] == "tieji-zhiqu" and choices[2] ~= "tieji-chuzheng" then
      player:broadcastSkillInvoke("mou__tieji", 2)
      if not to:isNude() then
        local card = room:askForCardChosen(player, to, "he", self.name)
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
    elseif choices[1] == "tieji-raozheng" and choices[2] ~= "tieji-huwei" then
      player:broadcastSkillInvoke("mou__tieji", 3)
      player:drawCards(2, self.name)
    else
      win = false
      player:broadcastSkillInvoke("mou__tieji", 4)
    end
    if win then
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn")
      if not player:isKongcheng() and #room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#joy_mou__tieji-discard") > 0 then
        local ids = room:getCardsFromPileByRule("slash")
        if #ids > 0 then
          room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonPrey, self.name)
        end
      end
    end
  end,
}
machao:addSkill(tieji)
Fk:loadTranslationTable{
  ["joy_mou__machao"] = "谋马超",
  ["#joy_mou__machao"] = "阻戎负勇",
  ["joy__yuma"] = "驭马",
  [":joy__yuma"] = "锁定技，你计算与其他角色距离-1；每当你失去装备区一张坐骑牌后，你摸两张牌。",
  ["joy_mou__tieji"] = "铁骑",
  [":joy_mou__tieji"] = "每当你使用【杀】指定其他角色为目标后，你可令其不能响应此【杀】，且所有非锁定技失效直到回合结束。然后你与其进行谋弈：①“直取敌营”，你获得其一张牌；②“扰阵疲敌”，你摸两张牌。若你谋奕成功，本回合使用【杀】上次数限+1，且可以弃置一张手牌，获得一张【杀】。",
  ["#joy_mou__tieji-discard"] = "铁骑：可以弃置一张手牌，获得一张【杀】",
}

local mouhuangzhong = General(extension, "joy_mou__huangzhong", "shu", 4)
local mouliegongFilter = fk.CreateFilterSkill{
  name = "#joy_mou__liegong_filter",
  card_filter = function(self, card, player)
    return card.trueName == "slash" and
      card.name ~= "slash" and
      not player:getEquipment(Card.SubtypeWeapon) and
      player:hasSkill(self) and
      table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card, player)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = "joy_mou__liegong"
    return c
  end,
}
local mouliegongProhibit = fk.CreateProhibitSkill{
  name = "#joy_mou__liegong_prohibit",
  prohibit_use = function(self, player, card)
    if Fk.currentResponsePattern ~= "jink" or card.name ~= "jink" or player:getMark("joy_mou__liegong") == 0 then
      return false
    end
    if table.contains(player:getMark("joy_mou__liegong"), card:getSuitString(true)) then
      return true
    end
  end,
}
local mouliegong = fk.CreateTriggerSkill{
  name = "joy_mou__liegong",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      data.card.trueName == "slash" and
      #AimGroup:getAllTargets(data.tos) == 1 and
      player:getMark("@joy_mouliegongRecord") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local logic = room.logic
    local cardUseEvent = logic:getCurrentEvent().parent
    cardUseEvent.liegong_used = true

    local to = room:getPlayerById(data.to)
    local suits = player:getMark("@joy_mouliegongRecord")
    room:setPlayerMark(to, self.name, suits)

    if #suits > 1 then
      local cards = room:getNCards(#suits - 1)
      room:moveCardTo(cards, Card.Processing)
      data.additionalDamage = data.additionalDamage or 0
      for _, id in ipairs(cards) do
        if table.contains(suits, Fk:getCardById(id):getSuitString(true)) then
          room:setCardEmotion(id, "judgegood")
          data.additionalDamage = data.additionalDamage + 1
        else
          room:setCardEmotion(id, "judgebad")
        end
        room:delay(200)
      end
      if not player.dead then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name)
      end
    end
  end,

  refresh_events = {fk.TargetConfirmed, fk.CardUsing, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self)) then return end
    local room = player.room
    if event == fk.CardUseFinished then
      return room.logic:getCurrentEvent().liegong_used
    else
      return data.card.suit ~= Card.NoSuit
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      room:setPlayerMark(player, "@joy_mouliegongRecord", 0)
      for _, p in ipairs(room:getAlivePlayers()) do
        room:setPlayerMark(p, "joy_mou__liegong", 0)
      end
    else
      local suit = data.card:getSuitString(true)
      local record = type(player:getMark("@joy_mouliegongRecord")) == "table" and player:getMark("@joy_mouliegongRecord") or {}
      table.insertIfNeed(record, suit)
      room:setPlayerMark(player, "@joy_mouliegongRecord", record)
    end
  end,
}
mouliegong:addRelatedSkill(mouliegongFilter)
mouliegong:addRelatedSkill(mouliegongProhibit)
mouhuangzhong:addSkill(mouliegong)
Fk:loadTranslationTable{
  ["joy_mou__huangzhong"] = "谋黄忠",
  ["#joy_mou__huangzhong"] = "没金铩羽",

  ["joy_mou__liegong"] = "烈弓",
  [":joy_mou__liegong"] = "若你未装备武器，你的【杀】只能当作普通【杀】使用或打出。"
   .. "你使用牌时或成为其他角色使用牌的目标后，若此牌的花色未被“烈弓”记录，"
   .. "则记录此种花色。当你使用【杀】指定唯一目标后，你可以亮出并获得牌堆顶的X张牌"
   .. "（X为你记录的花色数-1，且至少为0），然后每有一张牌花色与“烈弓”记录的"
   .. "花色相同，你令此【杀】伤害+1，且其不能使用“烈弓”记录花色的牌响应此"
   .. "【杀】。若如此做，此【杀】结算结束后，清除“烈弓”记录的花色。",

  ["@joy_mouliegongRecord"] = "烈弓",
  ["#joy_mou__liegong_filter"] = "烈弓",
}

local liubei = General(extension, "joy_mou__liubei", "shu", 4)
local rende = fk.CreateViewAsSkill{
  pattern = ".",
  name = "joy_mou__rende",
  interaction = function()
    local choices = {}
    if Self:getMark("@joy_mou__rende") > 1 and Self:getMark("joy_mou__rende_vs-turn") == 0 then
      for _, name in ipairs(U.getAllCardNames("bt")) do
        local card = Fk:cloneCard(name)
        if (Fk.currentResponsePattern == nil and Self:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card)) then
          if (card.type == Card.TypeBasic and Self:getMark("@joy_mou__rende") > 1)
          or (card:isCommonTrick() and Self:getMark("@joy_mou__rende") > 2) then
            table.insertIfNeed(choices, card.name)
          end
        end
      end
    end
    return UI.ComboBox {choices = choices}
  end,
  view_as = function(self)
    if not self.interaction.data then return nil end
    local c = Fk:cloneCard(self.interaction.data)
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:removePlayerMark(player, "@joy_mou__rende", use.card.type == Card.TypeBasic and 2 or 3)
    room:setPlayerMark(player, "joy_mou__rende_used-turn", 1)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@joy_mou__rende") > 1 and player:getMark("joy_mou__rende_prohibit-turn") == 0
    and player:getMark("joy_mou__rende_used-turn") == 0
  end,
  enabled_at_response = function (self, player, response)
    return player:getMark("@joy_mou__rende") > 1 and player:getMark("joy_mou__rende_prohibit-turn") == 0
    and player:getMark("joy_mou__rende_used-turn") == 0
  end,
}
-- FIXME : use skill_card to connet activeSkill and viewasSkill
local rende_give = fk.CreateActiveSkill{
  name = "joy_mou__rende&",
  main_skill = rende,
  prompt = "#joy_mou__rende-give",
  target_num = 1,
  min_card_num = 1,
  card_filter = Util.TrueFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and #selected_cards > 0
    and Fk:currentRoom():getPlayerById(to_select):getMark("joy_mou__rende_target-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "joy_mou__rende_target-phase", 1)
    room:setPlayerMark(target, "joy_mou__rende_target", 1)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead then return end
    room:setPlayerMark(player, "@joy_mou__rende", math.min(10, player:getMark("@joy_mou__rende") + #effect.cards))
  end,
  can_use = function (self, player, card)
    return player:getMark("joy_mou__rende_prohibit-turn") == 0
  end,
}
local rende_trigger = fk.CreateTriggerSkill{
  name = "#joy_mou__rende_trigger",
  mute = true,
  main_skill = rende,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(rende) and target == player and player.phase == Player.Play and player:getMark("@joy_mou__rende") < 10
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("joy_mou__rende")
    room:setPlayerMark(player, "@joy_mou__rende", math.min(10, player:getMark("@joy_mou__rende") + 3))
  end,
}
rende:addRelatedSkill(rende_give)
rende:addRelatedSkill(rende_trigger)
liubei:addSkill(rende)
local zhangwu = fk.CreateActiveSkill{
  name = "joy_mou__zhangwu",
  anim_type = "control",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  card_filter = function() return false end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local x = math.min(3, (room:getTag("RoundCount") - 1))
    if x > 0 then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if player.dead then break end
        if not p.dead and p:getMark("joy_mou__rende_target") > 0 and not p:isNude() then
          local cards = (#p:getCardIds("he") < x) and p:getCardIds("he") or
          room:askForCard(p, x, x, true, self.name, false, ".", "#mou__zhangwu-give::"..player.id..":"..x)
          if #cards > 0 then
            local dummy = Fk:cloneCard("dilu")
            dummy:addSubcards(cards)
            room:obtainCard(player, dummy, false, fk.ReasonGive)
          end
        end
      end
    end
    if not player.dead and player:isWounded() then
      room:recover { num = math.min(3,player.maxHp-player.hp), skillName = self.name, who = player, recoverBy = player}
    end
    room:setPlayerMark(player, "joy_mou__rende_prohibit-turn", 1)
  end,
}
liubei:addSkill(zhangwu)
local joy_mou__jijiang = fk.CreateTriggerSkill{
  name = "joy_mou__jijiang$",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local players = player.room.alive_players
      return #players > 2 and table.find(players, function(p) return p ~= player and p.kingdom == "shu" end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "joy_mou__jijiang_choose", "#joy_mou__jijiang-promot", true, nil, true)
    if success and dat then
      self.cost_data = dat.targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local victim = room:getPlayerById(self.cost_data[1])
    local bro = room:getPlayerById(self.cost_data[2])
    room:doIndicate(player.id, {bro.id})
    local choices = {"joy_mou__jijiang_skip"}
    if not bro:prohibitUse(Fk:cloneCard("slash")) and not bro:isProhibited(victim, Fk:cloneCard("slash")) then
      table.insert(choices, 1, "joy_mou__jijiang_slash:"..victim.id)
    end
    if room:askForChoice(bro, choices, self.name) == "joy_mou__jijiang_skip" then
      room:setPlayerMark(bro, "@@joy_mou__jijiang_skip", 1)
    else
      room:useVirtualCard("slash", nil, bro, victim, self.name, true)
    end
  end,
}
local joy_mou__jijiang_choose = fk.CreateActiveSkill{
  name = "joy_mou__jijiang_choose",
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected > 1 or to_select == Self.id then return false end
    if #selected == 0 then
      return true
    else
      local victim = Fk:currentRoom():getPlayerById(selected[1])
      local bro = Fk:currentRoom():getPlayerById(to_select)
      return bro.kingdom == "shu" and bro:inMyAttackRange(victim)
    end
  end,
}
Fk:addSkill(joy_mou__jijiang_choose)
local joy_mou__jijiang_delay = fk.CreateTriggerSkill{
  name = "#joy_mou__jijiang_delay",
  events = {fk.EventPhaseChanging},
  priority = 10,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@joy_mou__jijiang_skip") > 0 and data.to == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@joy_mou__jijiang_skip", 0)
    target:skip(Player.Play)
    return true
  end,
}
joy_mou__jijiang:addRelatedSkill(joy_mou__jijiang_delay)
liubei:addSkill(joy_mou__jijiang)
Fk:loadTranslationTable{
  ["joy_mou__liubei"] = "谋刘备",
  ["#joy_mou__liubei"] = "雄才盖世",
  ["joy_mou__rende"] = "仁德",
  [":joy_mou__rende"] = "①出牌阶段开始时，你获得3个“仁”标记；②出牌阶段，你可以将任意张牌交给一名本阶段未以此法获得牌的其他角色，获得等量的“仁”标记(至多拥有10个)。③每回合限一次，每当你需要使用或打出基本牌/普通锦囊牌时，你可以移去2/3个“仁”标记视为使用或打出之。",
  ["@joy_mou__rende"] = "仁",
  ["joy_mou__rende&"] = "仁德",
  ["#joy_mou__rende-give"] = "仁德：将任意张牌交给一名本阶段未以此法获得牌的其他角色，获得等量的“仁”标记",
  [":joy_mou__rende&"] = "出牌阶段，你可以将任意张牌交给一名本阶段未以此法获得牌的其他角色，获得等量的“仁”标记(至多拥有10个)。",
  ["joy_mou__zhangwu"] = "章武",
  [":joy_mou__zhangwu"] = "限定技，出牌阶段，你可以令〖仁德〗选择过的所有角色依次交给你X张牌（X为游戏轮数-1，至多为3），然后你回复3点体力，无法发动〖仁德〗直到回合结束。",
  ["joy_mou__jijiang"] = "激将",
  [":joy_mou__jijiang"] = "主公技，出牌阶段结束时，你可以选择一名其他角色，然后令一名攻击范围内含有其的其他蜀势力角色选择一项："..
  "1.视为对其使用一张【杀】；2.跳过下一个出牌阶段。",
  ["@@joy_mou__jijiang_skip"] = "激将",
  ["#joy_mou__jijiang-promot"] = "激将：先选择【杀】的目标，再选需要响应“激将”的蜀势力角色",
  ["joy_mou__jijiang_slash"] = "视为对 %src 使用一张【杀】",
  ["joy_mou__jijiang_skip"] = "跳过下一个出牌阶段",
  ["joy_mou__jijiang_choose"] = "激将",
}

local caocao = General(extension, "joy_mou__caocao", "wei", 4)
local mou__jianxiong = fk.CreateTriggerSkill{
  name = "joy_mou__jianxiong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
     return target == player and player:hasSkill(self) and ((data.card and target.room:getCardArea(data.card) == Card.Processing) or 2 - player:getMark("@joy_mou__jianxiong") > 0)
  end,
  on_use = function(self, event, target, player, data)
    if data.card and target.room:getCardArea(data.card) == Card.Processing then
      player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    end
    local num = 2 - player:getMark("@joy_mou__jianxiong")
    if num > 0 then
      player:drawCards(num, self.name)
    end
    local choices = {"getMark"}
    local n = "#joy_mou__jianxiong-getMark"
      if player:getMark("@joy_mou__jianxiong") ~= 0 then
        table.insert(choices,"removeMark")
        n = "#joy_mou__jianxiong-choose"
      end
    if player.room:askForSkillInvoke(player, self.name, nil, n) then
      local choice = player.room:askForChoice(player,choices,self.name)
      if choice == "getMark" then
        player.room:addPlayerMark(player,  "@joy_mou__jianxiong", 1)
      else
        player.room:removePlayerMark(player, "@joy_mou__jianxiong", 1)
      end
    end
  end,
}
local mou__jianxiong_gamestart = fk.CreateTriggerSkill{
  name = "#joy_mou__jianxiong_gamestart",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("joy_mou__jianxiong")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("joy_mou__jianxiong")
    local choice = room:askForChoice(player, {"0", "1", "2"}, "joy_mou__jianxiong", "#joy_mou__jianxiong-choice")
    room:addPlayerMark(player,  "@joy_mou__jianxiong", tonumber(choice))
  end,
}

local mou__qingzheng = fk.CreateTriggerSkill{
  name = "joy_mou__qingzheng",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local num = math.max(3 - player:getMark("@joy_mou__jianxiong"),0)
      local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suits, suit)
        end
      end
      return not player:isKongcheng() and #suits >= num
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#joy_mou__qingzheng-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(self.cost_data)
    local num = math.max(3 - player:getMark("@joy_mou__jianxiong"),0)
    local suits = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id):getSuitString()
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    local cards ={}
    for i = 1, num, 1 do
      local choice = room:askForChoice(player, suits, self.name, "#joy_mou__qingzheng-discard:::".. num ..":" ..i)
      table.removeOne(suits, choice)
        for _, c in ipairs(player.player_cards[Player.Hand]) do
          local suit = Fk:getCardById(c):getSuitString()
          if suit == choice then
            table.insertIfNeed(cards, c)
          end
        end
    end
    cards = table.filter(cards, function (id)
      return not player:prohibitDiscard(Fk:getCardById(id))
    end)
    if #cards > 0 then
      room:throwCard(cards, self.name, player)
    end
    if player.dead then return end
    local cids = to.player_cards[Player.Hand]
    local id1 = room:askForCardChosen(player, to, { card_data = { { "$Hand", cids }  } }, self.name, "#joy_mou__qingzheng-throw")
    local cards1 = table.filter(cids, function(id) return Fk:getCardById(id).suit == Fk:getCardById(id1).suit end)
    room:throwCard(cards1, self.name, to, player)
    if #cards > #cards1 and not to.dead then
      room:damage{ from = player, to = to, damage = 1, skillName = self.name }
      local choices = {"getMark"}
      local n = "#joy_mou__jianxiong-getMark"
      if player:getMark("@joy_mou__jianxiong") ~= 0 then
        table.insert(choices,"removeMark")
        n = "#joy_mou__jianxiong-choose"
      end
      if player.room:askForSkillInvoke(player, self.name, nil, n) then
        local choice = player.room:askForChoice(player,choices,self.name)
        if choice == "getMark" then
          player.room:addPlayerMark(player,  "@joy_mou__jianxiong", 1)
        else
          player.room:removePlayerMark(player, "@joy_mou__jianxiong", 1)
        end
      end
    end
  end,
}

mou__jianxiong:addRelatedSkill(mou__jianxiong_gamestart)
caocao:addSkill(mou__jianxiong)
caocao:addSkill(mou__qingzheng)
caocao:addSkill("mou__hujia")

Fk:loadTranslationTable{
  ["joy_mou__caocao"] = "谋曹操",
  ["#joy_mou__caocao"] = "魏武大帝",

  ["joy_mou__jianxiong"] = "奸雄",
  ["#joy_mou__jianxiong_gamestart"] = "奸雄",
  [":joy_mou__jianxiong"] = "游戏开始时，你可以获得至多两枚“治世”标记。当你受到伤害后，你可以获得对你造成伤害的牌并摸2-X张牌，然后你可以增减1枚“治世”。"..
  "（X为“治世”的数量）。",
  ["joy_mou__qingzheng"] = "清正",
  [":joy_mou__qingzheng"] = "出牌阶段开始时，你可以选择一名有手牌的其他角色，你弃置3-X（X为你的“治世”标记数）种花色的所有手牌，然后观看其手牌并选择一种"..
  "花色的牌，其弃置所有该花色的手牌。若如此做且其弃置的手牌小于你以此法弃置的牌数，你对其造成1点伤害，然后你可以增减一枚“治世”。",

  ["#joy_mou__jianxiong-choose"] = "是否选择增减一枚“治世”标记？",
  ["#joy_mou__jianxiong-getMark"] = "是否增加一枚“治世”标记？",
  ["#joy_mou__jianxiong-choice"] = "奸雄：请选择要获得的“治世”标记数量。",
  ["#joy_mou__qingzheng-choose"] = "清正：你可以发动“清正”选择一名有手牌的其他角色",
  ["#joy_mou__qingzheng-discard"] = "清正：请选择一种花色的所有牌弃置，总共%arg 次 现在是第%arg2 次",
  ["#joy_mou__qingzheng-throw"] = "清正：弃置其一种花色的所有手牌",
  ["@joy_mou__jianxiong"] = "治世",

  ["getMark"] = "增加一枚标记",
  ["removeMark"] = "减少一枚标记",

}

return extension
