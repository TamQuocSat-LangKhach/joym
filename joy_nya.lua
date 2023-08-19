local extension = Package("joy_nya")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_nya"] = "欢乐-喵",
  ["nya"] = "喵",
}

local nya__play = fk.CreateTriggerSkill{
  name = "nya__play",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (player.phase == Player.Start or player.phase == Player.Finish) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Start then
      local to, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
        return p.id end), 1, 1, ".", "#nya__play-choose", self.name, true)
      if #to > 0 and card then
        self.cost_data = {to[1], card}
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      room:throwCard(self.cost_data[2], self.name, player, player)
      room:handleAddLoseSkills(player, "-nya__play", nil, true, false)
      local to = room:getPlayerById(self.cost_data[1])
      if not to.dead then
        room:handleAddLoseSkills(to, "nya__play", nil, true, false)
        to:drawCards(1, self.name)
      end
    else
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
}
Fk:loadTranslationTable{
  ["nya__play"] = "逗猫",
  [":nya__play"] = "准备阶段，你可以弃置一张牌选择一名其他角色，将〖逗猫〗转移给该角色，然后其摸一张牌。结束阶段，若你有〖逗猫〗，你需弃置一张牌。",
  ["#nya__play-choose"] = "逗猫：你可以弃置一张牌将〖逗猫〗转移给一名角色，然后其摸一张牌",
}

local caiwenji = General(extension, "nya__caiwenji", "qun", 3, 3, General.Female)
local function NyaBeige(player, target, src, suit)
  local room = player.room
  local to = target
  if suit == "club" or suit == "spade" then
    to = src
  end
  if not to or to.dead then return end
  if suit == "heart" then
    if to:isWounded() then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = "nya__beige",
      }
    end
  elseif suit == "diamond" then
    to:drawCards(2, "nya__beige")
  elseif suit == "club" then
    if #to:getCardIds("he") < 3 then
      to:throwAllCards("he")
    else
      room:askForDiscard(to, 2, 2, true, "nya__beige", false, ".")
    end
  elseif suit == "spade" then
    to:turnOver()
  end
end
local nya__beige = fk.CreateTriggerSkill{
  name = "nya__beige",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and not data.to.dead and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#nya__beige-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suit = Fk:getCardById(self.cost_data[1]):getSuitString()
    room:throwCard(self.cost_data, self.name, player, player)
    NyaBeige(player, target, data.from, suit)
    if not player.dead and not player:hasSkill("nya__play", true) then
      local all_choices = {"Cancel", "nya__beige1", "nya__beige2", "nya__beige3", "nya__beige4"}
      local choices = table.simpleClone(all_choices)
      if target.dead then
        table.removeOne(choices, "nya__beige1")
        table.removeOne(choices, "nya__beige2")
      elseif not target:isWounded() then
        table.removeOne(choices, "nya__beige1")
      end
      if not data.from or data.from.dead then
        table.removeOne(choices, "nya__beige3")
        table.removeOne(choices, "nya__beige4")
      elseif data.from:isNude() then
        table.removeOne(choices, "nya__beige3")
      end
      local choice = room:askForChoice(player, choices, self.name, "#nya__beige-choice::"..target.id, false, all_choices)
      if choice ~= "Cancel" then
        local suits = {"", "heart", "diamond", "club", "spade"}
        suit = suits[table.indexOf(all_choices, choice)]
        NyaBeige(player, target, data.from, suit)
      end
    end
  end,
}
local nya__duanchang = fk.CreateTriggerSkill{
  name = "nya__duanchang",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Death, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if target == player and data.damage and data.damage.from and not data.damage.from.dead then
      if event == fk.Death then
        return player:hasSkill(self.name, false, true)
      else
        return player:hasSkill(self.name) and not player:hasSkill("nya__play", true) and not data.damage.from:isNude()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.damage.from
    if event == fk.Death then
      local skills = {}
      for _, s in ipairs(to.player_skills) do
        if not (s.attached_equip or s.name[#s.name] == "&") then
          table.insertIfNeed(skills, s.name)
        end
      end
      if room.settings.gameMode == "m_1v2_mode" and to.role == "lord" then
        table.removeOne(skills, "m_feiyang")
        table.removeOne(skills, "m_bahu")
      end
      if #skills > 0 then
        room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"), nil, true, false)
      end
    else
      room:doIndicate(player.id, {to.id})
      if #to:getCardIds("he") < 3 then
        to:throwAllCards("he")
      else
        room:askForDiscard(to, 2, 2, true, self.name, false, ".")
      end
    end
  end,
}
caiwenji:addSkill(nya__beige)
caiwenji:addSkill(nya__duanchang)
caiwenji:addSkill(nya__play)
Fk:loadTranslationTable{
  ["nya__caiwenji"] = "文姬喵",
  ["nya__beige"] = "悲歌",
  [":nya__beige"] = "当一名角色受到【杀】造成的伤害后，你可以弃置一张牌，若弃置的牌为：<font color='red'>♥</font>，其回复1点体力；"..
  "<font color='red'>♦</font>，其摸两张牌；♣，伤害来源弃置两张牌；♠，伤害来源翻面。然后若你没有〖逗猫〗，则你额外选择一个选项。",
  ["nya__duanchang"] = "断肠",
  [":nya__duanchang"] = "锁定技，当你死亡时，杀死你的角色失去所有武将技能。当你进入濒死状态时，若你没有〖逗猫〗，伤害来源需弃置两张牌。",
  ["#nya__beige-invoke"] = "悲歌：%dest 受到伤害，你可以弃置一张牌，根据花色执行效果",
  ["nya__beige1"] = "回复1点体力",
  ["nya__beige2"] = "摸两张牌",
  ["nya__beige3"] = "伤害来源弃两张牌",
  ["nya__beige4"] = "伤害来源翻面",
  ["#nya__beige-choice"] = "悲歌：你可以再令 %dest 执行一项",
}

local diaochan = General(extension, "nya__diaochan", "qun", 3, 3, General.Female)
local nya__lijian = fk.CreateActiveSkill{
  name = "nya__lijian",
  anim_type = "offensive",
  min_card_num = 1,
  min_target_num = 2,
  prompt = function(self)
    if not Self:hasSkill("nya__play", true) then
      return "#nya__lijian2"
    else
      return "#nya__lijian1"
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected < #Fk:currentRoom().alive_players - (Self:hasSkill("nya__play", true) and 1 or 0) and
      not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected < #selected_cards + (Self:hasSkill("nya__play", true) and 0 or 1)
  end,
  feasible = function (self, selected, selected_cards)
    return #selected > 1 and #selected == #selected_cards + (Self:hasSkill("nya__play", true) and 0 or 1)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local tos = table.simpleClone(effect.tos)
    room:sortPlayersByAction(tos, false)
    local targets = table.map(tos, function(id) return room:getPlayerById(id) end)
    for _, src in ipairs(targets) do
      if not src.dead then
        if table.contains(tos, src.id) then
          local dest = src:getNextAlive()
          while not table.contains(targets, dest) do
            dest = dest:getNextAlive()
          end
          if dest == src then break end
          table.removeOne(tos, src.id)
          room:useVirtualCard("duel", nil, src, dest, self.name)
        else
          break
        end
      end
    end
  end,
}
local nya__biyue = fk.CreateTriggerSkill{
  name = "nya__biyue",
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local tos = {}
    player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 999, function(e)
      local damage = e.data[5]
      if damage then
        table.insertIfNeed(tos, damage.to.id)
      end
    end, Player.HistoryTurn)
    local n = not player:hasSkill("nya__play", true) and 2 or 1
    player:drawCards(math.min(n + #tos, 5), self.name)
  end,
}
diaochan:addSkill(nya__lijian)
diaochan:addSkill(nya__biyue)
diaochan:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__diaochan"] = "貂蝉喵",
  ["nya__lijian"] = "离间",
  [":nya__lijian"] = "出牌阶段限一次，你可以选择至少两名角色并弃置X张牌（X为你选择的角色数，若你没有〖逗猫〗则-1），这些角色依次视为对"..
  "逆时针方向下一名目标角色使用一张【决斗】。",
  ["nya__biyue"] = "闭月",
  [":nya__biyue"] = "锁定技，结束阶段，你摸X张牌（X为本回合受到过伤害的角色数+1，若你没有〖逗猫〗则改为+2，至多为5）。",
  ["#nya__lijian1"] = "离间：弃置任意张牌，选择等量的角色互相【决斗】！",
  ["#nya__lijian2"] = "离间：弃置任意张牌，选择弃牌数+1的角色互相【决斗】！",
}

local caifuren = General(extension, "nya__caifuren", "qun", 3, 3, General.Female)
local nya__qieting = fk.CreateTriggerSkill{
  name = "nya__qieting",
  anim_type = "control",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and data.to == Player.NotActive
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1"}
    if target:canMoveCardsInBoardTo(player, "e") then
      table.insert(choices, 1, "nya__qieting_move")
    end
    local choice = room:askForChoice(player, choices, self.name, "#nya__qieting-choice::"..target.id)
    if choice == "nya__qieting_move" then
      room:doIndicate(player.id, {target.id})
      room:askForMoveCardInBoard(player, target, player, self.name, "e", target)
    else
      player:drawCards(1, self.name)
    end
    if target:hasSkill("nya__play", true) and not player.dead then
      choices = {"Cancel", "draw1"}
      if not target:isKongcheng() then
        table.insert(choices, 2, "nya__qieting_prey")
      end
      choice = room:askForChoice(player, choices, self.name, "#nya__qieting-choice::"..target.id)
      if choice == "nya__qieting_prey" then
        room:doIndicate(player.id, {target.id})
        local ids = table.random(target:getCardIds("h"), 2)
        local result = room:askForGuanxing(player, ids, {0, 2}, {1, 1}, self.name, true, {target.general, "nya__qieting_get"})
        local id
        if #result.bottom > 0 then
          id = result.bottom[1]
        else
          id = table.random(target:getCardIds("h"))
        end
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
      elseif choice == "draw1" then
        player:drawCards(1, self.name)
      end
    end
  end,
}
local nya__xianzhou = fk.CreateActiveSkill{
  name = "nya__xianzhou",
  anim_type = "control",
  min_card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  prompt = "#nya__xianzhou",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return true
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #effect.cards
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target, dummy, false, fk.ReasonGive)
    if target.dead then return end
    local targets = table.map(table.filter(room:getOtherPlayers(target), function(p)
      return target:inMyAttackRange(p) end), function(p) return p.id end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(target, targets, 1, n, "#xianzhou-choose:"..player.id.."::"..n, self.name, true)
      if #tos > 0 then
        for _, p in ipairs(tos) do
          room:damage{
            from = target,
            to = room:getPlayerById(p),
            damage = 1,
            skillName = self.name,
          }
        end
      else
        if player:isWounded() and not player.dead then
          room:recover({
            who = player,
            num = math.min(n, player:getLostHp()),
            recoverBy = target,
            skillName = self.name
          })
        end
      end
    end
  end,
}
local nya__xianzhou_trigger = fk.CreateTriggerSkill{
  name = "#nya__xianzhou_trigger",
  mute = true,
  events = {fk.EventAcquireSkill},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("nya__xianzhou", Player.HistoryGame) > 0 and data.name == "nya__play"
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:setSkillUseHistory("nya__xianzhou", 0, Player.HistoryGame)
  end,
}
nya__xianzhou:addRelatedSkill(nya__xianzhou_trigger)
caifuren:addSkill(nya__qieting)
caifuren:addSkill(nya__xianzhou)
caifuren:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__caifuren"] = "蔡夫人喵",
  ["nya__qieting"] = "窃听",
  [":nya__qieting"] = "其他角色回合结束时，你可以选择一项：1.将其装备区内一张牌移至你的装备区；2.摸一张牌。若其有〖逗猫〗，你可以再选择一项："..
  "1.观看其两张手牌并获得其中一张牌；2.摸一张牌。",
  ["nya__xianzhou"] = "献州",
  [":nya__xianzhou"] = "限定技，出牌阶段，你可以将任意张牌交给一名其他角色，然后该角色选择一项：1.令你回复X点体力；2.对其攻击范围内的至多X名"..
  "角色各造成1点伤害（X为你以此法交给其的牌数）。当你获得〖逗猫〗时，〖献州〗视为未发动过。",
  ["#nya__xianzhou"] = "献州：将任意张牌交给一名其他角色，其选择造成伤害或令你回复体力",
  ["#nya__qieting-choice"] = "窃听：选择对 %dest 执行的一项",
  ["nya__qieting_move"] = "将其一张装备移动给你",
  ["nya__qieting_prey"] = "观看其两张手牌并获得一张",
  ["nya__qieting_get"] = "获得",
}

local xingcai = General(extension, "nya__xingcai", "shu", 3, 3, General.Female)
local nya__shenxian = fk.CreateTriggerSkill{
  name = "nya__shenxian",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.extra_data and move.extra_data.nya__shenxian then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason == fk.ReasonDiscard then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from ~= player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local card = Fk:getCardById(info.cardId)
            if card.type == Card.TypeBasic or (not player:hasSkill("nya__play", true) and card.type ~= Card.TypeEquip) then
              move.extra_data = move.extra_data or {}
              move.extra_data.nya__shenxian = true
              return
            end
          end
        end
      end
    end
  end,
}
local nya__qiangwu = fk.CreateTargetModSkill{
  name = "nya__qiangwu",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(self.name) and card and card.trueName == "slash" and to:hasSkill("nya__play", true)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(self.name) and card and card.trueName == "slash" and not to:hasSkill("nya__play", true)
  end,
}
local nya__qiangwu_trigger = fk.CreateTriggerSkill{
  name = "#nya__qiangwu_trigger",
  mute = true,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("nya__qiangwu") and data.card and data.card.trueName == "slash" and
      player:hasSkill("nya__play", true)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("nya__qiangwu")
    room:notifySkillInvoked(player, "nya__qiangwu", "drawcard")
    player:drawCards(1, "nya__qiangwu")
  end,
}
nya__qiangwu:addRelatedSkill(nya__qiangwu_trigger)
xingcai:addSkill(nya__shenxian)
xingcai:addSkill(nya__qiangwu)
xingcai:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__xingcai"] = "星彩喵",
  ["nya__shenxian"] = "甚贤",
  [":nya__shenxian"] = "每回合限一次，其他角色因弃置失去基本牌后，你可以摸一张牌；若你没有〖逗猫〗，则改为弃置非装备牌即可发动。",
  ["nya__qiangwu"] = "枪舞",
  [":nya__qiangwu"] = "你对没有〖逗猫〗的角色使用【杀】无距离限制，对有〖逗猫〗的角色使用【杀】无次数限制。若你有〖逗猫〗，当你使用【杀】"..
  "造成伤害后，你摸一张牌。",
}

local zhurong = General(extension, "nya__zhurong", "shu", 4, 4, General.Female)
local nya__juxiang = fk.CreateTriggerSkill{
  name = "nya__juxiang",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect, fk.CardUseFinished, fk.AfterCardsMove, fk.AfterCardUseDeclared, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from ~= player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).trueName == "savage_assault" and player.room:getCardArea(info.cardId) == Card.DiscardPile then
                return true
              end
            end
          end
        end
      elseif data.card and data.card.trueName == "savage_assault" then
        if event == fk.PreCardEffect then
          return data.to == player.id
        elseif event == fk.CardUseFinished then
          return target ~= player and player.room:getCardArea(data.card) == Card.Processing
        elseif event == fk.AfterCardUseDeclared then
          return target == player
        elseif event == fk.DamageCaused then
          return target == player and not data.to:hasSkill("nya__play", true)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(self.name)
    if event == fk.PreCardEffect then
      room:notifySkillInvoked(player, self.name, "defensive")
      return true
    elseif event == fk.AfterCardsMove then
      local ids = {}
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).trueName == "savage_assault" and room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
      if #ids > 0 then
        room:notifySkillInvoked(player, self.name, "drawcard")
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(ids)
        room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
      end
    elseif event == fk.CardUseFinished then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    elseif event == fk.AfterCardUseDeclared then
      room:notifySkillInvoked(player, self.name, "offensive")
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(room.alive_players) do
        if p:hasSkill("nya__play", true) then
          table.insertIfNeed(data.disresponsiveList, p.id)
        end
      end
    elseif event == fk.DamageCaused then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    end
  end,
}
local nya__lieren = fk.CreateTriggerSkill{
  name = "nya__lieren",
  anim_type = "control",
  events = {fk.TargetSpecified, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.TargetSpecified then
        if data.card and data.card.trueName == "slash" and not player:isKongcheng() then
          local to = player.room:getPlayerById(data.to)
          return not to.dead and not to:isKongcheng()
        end
      else
        return player.phase == Player.Play and not player:isKongcheng() and
          player:usedSkillTimes("nya__play", Player.HistoryTurn) > 0 and not player:hasSkill("nya__play", true) and
          table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      self:doCost(event, target, player, data.to)
    else
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      if room:askForSkillInvoke(player, self.name, nil, "#nya__lieren-invoke::"..data) then
        room:doIndicate(player.id, {data})
        return true
      end
    else
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isKongcheng() end), function(p) return p.id end),
        1, 1, "#nya__lieren-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local to = room:getPlayerById(data)
      local pindian = player:pindian({to}, self.name)
      if room:getCardArea(pindian.results[to.id].toCard) == Card.DiscardPile then
        room:delay(1000)
        room:obtainCard(player, pindian.results[to.id].toCard, true, fk.ReasonJustMove)
      end
      if pindian.results[to.id].winner == player and not player.dead and not to.dead and not to:isNude() then
        local id = room:askForCardChosen(player, to, "he", self.name)
        room:obtainCard(player, id, false, fk.ReasonPrey)
      end
    else
      self:use(fk.TargetSpecified, player, player, self.cost_data)
    end
  end,
}
zhurong:addSkill(nya__juxiang)
zhurong:addSkill(nya__lieren)
zhurong:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__zhurong"] = "祝融喵",
  ["nya__juxiang"] = "巨象",
  [":nya__juxiang"] = "锁定技，【南蛮入侵】对你无效；其他角色使用或弃置的【南蛮入侵】进入弃牌堆时，你获得之；你使用【南蛮入侵】不能被有〖逗猫〗"..
  "的角色响应，对没有〖逗猫〗的角色造成伤害时，你摸一张牌。",
  ["nya__lieren"] = "烈刃",
  [":nya__lieren"] = "当你使用【杀】指定目标后，你可以与其拼点并获得其拼点牌，若你赢，你获得其一张牌。出牌阶段开始时，若你本回合失去了〖逗猫〗，"..
  "你可以发动〖烈刃〗。",
  ["#nya__lieren-invoke"] = "烈刃：你可以与 %dest 拼点并获得其拼点牌，若你赢，你获得其一张牌",
  ["#nya__lieren-choose"] = "烈刃：你可以对一名角色发动〖烈刃〗的拼点效果",
}

local huangyueying = General(extension, "nya__huangyueying", "shu", 3, 3, General.Female)
local nya__jizhi = fk.CreateTriggerSkill{
  name = "nya__jizhi",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.type == Card.TypeTrick
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local nya__jizhi_trigger = fk.CreateTriggerSkill{
  name = "#nya__jizhi_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("nya__jizhi") and target ~= player and data.card.type == Card.TypeTrick and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("nya__jizhi")
    room:notifySkillInvoked(player, "nya__jizhi")
    player:drawCards(1, "nya__jizhi")
  end,
}
local nya__qicai = fk.CreateTargetModSkill{
  name = "nya__qicai",
  frequency = Skill.Compulsory,
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(self.name) and card and card.type == Card.TypeTrick
  end,
}
local nya__qicai_trigger = fk.CreateTriggerSkill{
  name = "#nya__qicai_trigger",
  mute = true,
  events = {fk.BeforeCardsMove, fk.EventAcquireSkill},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.BeforeCardsMove then
        if player:getEquipment(Card.SubtypeArmor) then
          for _, move in ipairs(data) do
            if move.from == player.id and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerEquip and info.cardId == player:getEquipment(Card.SubtypeArmor) then
                  return true
                end
              end
            end
          end
        end
      else
        return data.name == "nya__play" and target ~= player and player.room:getTag("RoundCount")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("nya__qicai")
    if event == fk.BeforeCardsMove then
      for _, move in ipairs(data) do
        for i = #move.moveInfo, 1, -1 do
          local info = move.moveInfo[i]
          if info.fromArea == Card.PlayerEquip and info.cardId == player:getEquipment(Card.SubtypeArmor) then
            table.removeOne(move.moveInfo, info)
            room:notifySkillInvoked(player, "nya__qicai", "defensive")
            break
          end
        end
      end
    else
      room:notifySkillInvoked(player, "nya__qicai", "drawcard")
      local card = room:getCardsFromPileByRule(".|.|.|.|.|trick")
      if #card > 0 then
        room:moveCards({
          ids = card,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = "nya__qicai",
        })
      end
    end
  end,
}
nya__jizhi:addRelatedSkill(nya__jizhi_trigger)
nya__qicai:addRelatedSkill(nya__qicai_trigger)
huangyueying:addSkill(nya__jizhi)
huangyueying:addSkill(nya__qicai)
huangyueying:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__huangyueying"] = "月英喵",
  ["nya__jizhi"] = "集智",
  [":nya__jizhi"] = "当你使用锦囊牌时，你可以摸一张牌；每回合限一次，当其他角色使用锦囊牌时，若你没有〖逗猫〗，你摸一张牌。",
  ["nya__qicai"] = "奇才",
  [":nya__qicai"] = "锁定技，你使用锦囊牌无距离限制；其他角色不能弃置你装备区内的防具。当其他角色获得〖逗猫〗时，你从牌堆随机获得一张锦囊牌。",
}

local daqiao = General(extension, "nya__daqiao", "wu", 3, 3, General.Female)
local nya__guose = fk.CreateActiveSkill{
  name = "nya__guose",
  anim_type = "control",
  min_card_num = 0,
  max_card_num = 1,
  target_num = 1,
  prompt = "#nya__guose",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 4
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if #selected_cards == 0 then
        return target:hasDelayedTrick("indulgence")
      else
        local card = Fk:cloneCard("indulgence")
        card:addSubcard(selected_cards[1])
        return to_select ~= Self.id and not Self:isProhibited(target, card)
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if #effect.cards == 0 then
      for _, id in ipairs(target:getCardIds("j")) do
        local card = target:getVirualEquip(id)
        if not card then card = Fk:getCardById(id) end
        if card.name == "indulgence" then
          room:throwCard({id}, self.name, target, player)
        end
      end
    else
      room:useVirtualCard("indulgence", effect.cards, player, target, self.name)
    end
    if not player.dead then
      if not player:hasSkill("nya__play", true) then
        player:drawCards(2, self.name)
        room:askForDiscard(player, 1, 1, true, self.name, false)
      else
        player:drawCards(1, self.name)
      end
    end
  end,
}
local nya__liuli = fk.CreateTriggerSkill{
  name = "nya__liuli",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and
      table.find(player.room.alive_players, function(p)
        return p ~= player and p.id ~= data.from and player:inMyAttackRange(p) and
          not player.room:getPlayerById(data.from):isProhibited(p, data.card) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local from = room:getPlayerById(data.from)
    for _, p in ipairs(room.alive_players) do
      if p ~= player and p.id ~= data.from and player:inMyAttackRange(p) and not from:isProhibited(p, data.card) then
        table.insert(targets, p.id)
      end
    end
    local n = not player:hasSkill("nya__play", true) and 2 or 1
    local tos, card = room:askForChooseCardAndPlayers(player, targets, 1, n, nil,
      "#nya__liuli-choose:::"..n..":"..data.card:toLogString(), self.name, true)
    if #tos > 0 then
      self.cost_data = {tos, card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data[2], self.name, player, player)
    TargetGroup:removeTarget(data.targetGroup, player.id)
    for _, id in ipairs(self.cost_data[1]) do
      room:doIndicate(player.id, {id})
      TargetGroup:pushTargets(data.targetGroup, id)
    end
  end,
}
daqiao:addSkill(nya__guose)
daqiao:addSkill(nya__liuli)
daqiao:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__daqiao"] = "大乔喵",
  ["nya__guose"] = "国色",
  [":nya__guose"] = "出牌阶段限四次，你可以将一张<font color='red'>♦</font>牌当【乐不思蜀】使用，或弃置场上一张【乐不思蜀】；然后你摸一张牌。"..
  "若你没有〖逗猫〗，则改为摸两张牌并弃置一张牌。",
  ["nya__liuli"] = "流离",
  [":nya__liuli"] = "当你成为【杀】的目标时，你可以弃置一张牌转移给你攻击范围内一名其他角色；若你没有〖逗猫〗，则可以选择两名。",
  ["#nya__guose"] = "国色：将一张<font color='red'>♦</font>牌当【乐不思蜀】使用；或弃置场上一张【乐不思蜀】",
  ["#nya__liuli-choose"] = "流离：你可以弃置一张牌，将此%arg2转移给%arg名角色",
}

local xiaoqiao = General(extension, "nya__xiaoqiao", "wu", 3, 3, General.Female)
local nya__tianxiang = fk.CreateTriggerSkill{
  name = "nya__tianxiang",
  anim_type = "offensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local to, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, ".|.|heart|hand", "#nya__tianxiang-choose", self.name, true)
    if #to > 0 and card then
      self.cost_data = {to[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:obtainCard(to.id, self.cost_data[2], true, fk.ReasonGive)
    local damage = table.simpleClone(data)
    damage.to = to
    room:damage(damage)
    if not to.dead then
      if to:hasSkill("nya__play", true) then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = self.name,
        }
      elseif not to:isNude() and not player.dead then
        local id = room:askForCardChosen(player, to, "he", self.name)
        room:throwCard({id}, self.name, to, player)
      end
    end
    return true
  end,
}
local nya__hongyan = fk.CreateFilterSkill{
  name = "nya__hongyan",
  frequency = Skill.Compulsory,
  card_filter = function(self, to_select, player)
    return player:hasSkill(self.name) and to_select.suit == Card.Spade
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, to_select.number)
  end,
}
local nya__hongyan_trigger = fk.CreateTriggerSkill{
  name = "#nya__hongyan_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.FinishJudge},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("nya__hongyan") and not target:hasSkill("nya__play", true) and data.card.suit == Card.Heart
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("nya__hongyan")
    room:notifySkillInvoked(player, "nya__hongyan", "support")
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "nya__hongyan",
      }
    end
    if not player.dead then
      player:drawCards(1, "nya__hongyan")
    end
  end,
}
nya__hongyan:addRelatedSkill(nya__hongyan_trigger)
xiaoqiao:addSkill(nya__tianxiang)
xiaoqiao:addSkill(nya__hongyan)
xiaoqiao:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__xiaoqiao"] = "小乔喵",
  ["nya__tianxiang"] = "天香",
  [":nya__tianxiang"] = "当你受到伤害时，你可以交给一名其他角色一张<font color='red'>♥</font>手牌，将此伤害转移给其。然后若其有〖逗猫〗，"..
  "你对其造成1点伤害；没有〖逗猫〗，你弃置其一张牌。",
  ["nya__hongyan"] = "红颜",
  [":nya__hongyan"] = "锁定技，你的♠牌视为<font color='red'>♥</font>牌。没有〖逗猫〗的角色判定牌生效后，若结果为<font color='red'>♥</font>，"..
  "你回复1点体力并摸一张牌。",
  ["#nya__tianxiang-choose"] = "天香：你可以交给一名其他角色一张<font color='red'>♥</font>手牌，将此伤害转移给其",
}

local sunshangxiang = General(extension, "nya__sunshangxiang", "wu", 3, 3, General.Female)
local nya__jieyi = fk.CreateActiveSkill{
  name = "nya__jieyi",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#nya__jieyi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id and #selected_cards == 1 then
      if Fk:currentRoom():getCardArea(selected_cards[1]) == Player.Hand then
        return true
      else
        local target = Fk:currentRoom():getPlayerById(to_select)
        local card = Fk:getCardById(selected_cards[1])
        return #target:getAvailableEquipSlots(card.sub_type) > 0
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if room:getCardArea(effect.cards[1]) == Player.Hand then
      room:obtainCard(target, effect.cards[1], false, fk.ReasonGive)
    else
      room:moveCards({
        ids = effect.cards,
        from = effect.from,
        to = effect.tos[1],
        toArea = Card.PlayerEquip,
        skillName = self.name,
        moveReason = fk.ReasonPut,
      })
    end
    if player.dead then return end
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    player:drawCards(1, self.name)
    if player.dead or target.dead then return end
    if not player:hasSkill("nya__play", true) and room:askForSkillInvoke(player, self.name, nil, "#nya__jieyi-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      if target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      target:drawCards(1, self.name)
    end
  end,
}
local nya__xiaoji = fk.CreateTriggerSkill{
  name = "nya__xiaoji",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
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
          if info.fromArea == Card.PlayerEquip then
            n = n + 1
          end
        end
      end
    end
    self.cancel_cost = false
    for i = 1, n, 1 do
      if self.cancel_cost or not player:hasSkill(self.name) or player.dead then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, self.name)
    if not player.dead and not player:hasSkill("nya__play", true) then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return #p:getCardIds("ej") > 0 end), function(p) return p.id end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#nya__xiaoji-choose", self.name)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        local id = room:askForCardChosen(player, to, "ej", self.name)
        room:throwCard({id}, self.name, to, player)
      end
    end
  end,
}
sunshangxiang:addSkill(nya__jieyi)
sunshangxiang:addSkill(nya__xiaoji)
sunshangxiang:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__sunshangxiang"] = "香香喵",
  ["nya__jieyi"] = "结谊",
  [":nya__jieyi"] = "出牌阶段限一次，你可以选择一名其他角色，交给其一张手牌或将装备区内一张装备牌置入其装备区，然后你回复1点体力并摸一张牌；"..
  "若你没有〖逗猫〗，你可以令其也回复1点体力并摸一张牌。",
  ["nya__xiaoji"] = "枭姬",
  [":nya__xiaoji"] = "当你失去装备区内一张牌后，你可以摸两张牌，然后若你没有〖逗猫〗，你可以弃置场上一张牌。",
  ["#nya__jieyi"] = "结谊：你可以交给一名其他角色一张手牌，或将装备区内一张装备置入其装备区",
  ["#nya__jieyi-invoke"] = "结谊：你可以令 %dest 也回复1点体力并摸一张牌",
  ["#nya__xiaoji-choose"] = "枭姬：你可以弃置场上一张牌",
}

local zhenji = General(extension, "nya__zhenji", "wei", 3, 3, General.Female)
local nya__luoshen = fk.CreateTriggerSkill{
  name = "nya__luoshen",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (player.phase == Player.Start or (player.phase == Player.Finish and not player:hasSkill("nya__play", true)))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    while true do
      local judge = {
        who = player,
        reason = self.name,
        pattern = ".|.|spade,club",
        skipDrop = true,
      }
      room:judge(judge)
      table.insert(cards, judge.card)
      if judge.card.color ~= Card.Black or not room:askForSkillInvoke(player, self.name) then
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
local nya__qingguo = fk.CreateViewAsSkill{
  name = "nya__qingguo",
  anim_type = "defensive",
  pattern = "jink,peach",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local card = Fk:getCardById(to_select)
    local c
    if card.color == Card.Black then
      c = Fk:cloneCard("jink")
    elseif not Self:hasSkill("nya__play", true) and card.trueName == "jink" then
      c = Fk:cloneCard("peach")
    else
      return false
    end
    return (Fk.currentResponsePattern == nil and c.skill:canUse(Self)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:getCardById(cards[1])
    local c
    if card.color == Card.Black then
      c = Fk:cloneCard("jink")
    elseif card.trueName == "jink" then
      c = Fk:cloneCard("peach")
    end
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return not player:hasSkill("nya__play", true)
  end,
  enabled_at_response = function(self, player, response)
    if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) then
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("peach")) then
        return not response and not player:hasSkill("nya__play", true)
      else
        return true
      end
    end
  end,
}
zhenji:addSkill(nya__luoshen)
zhenji:addSkill(nya__qingguo)
zhenji:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__zhenji"] = "甄姬喵",
  ["nya__luoshen"] = "洛神",
  [":nya__luoshen"] = "准备阶段，你可以进行判定：若为黑色，你获得之，然后可以重复此流程；若为红色，你获得之。若你没有〖逗猫〗，结束阶段你也可以"..
  "发动〖洛神〗。",
  ["nya__qingguo"] = "倾国",
  [":nya__qingguo"] = "你可以将一张黑色牌当【闪】使用或打出；若你没有〖逗猫〗，你可以将一张【闪】当【桃】使用。",
}

local zhangchunhua = General(extension, "nya__zhangchunhua", "wei", 3, 3, General.Female)
local nya__jueqing = fk.CreateTriggerSkill{
  name = "nya__jueqing",
  anim_type = "offensive",
  events = {fk.PreDamage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#nya__jueqing-invoke::"..data.to.id..":"..data.damage) then
      room:loseHp(player, data.damage, self.name)
      data.damage = data.damage * 2
    end
    room:loseHp(data.to, data.damage, self.name)
    return true
  end,
}
local nya__shangshi = fk.CreateTriggerSkill{
  name = "nya__shangshi",
  anim_type = "drawcard",
  events = {fk.HpChanged, fk.MaxHpChanged, fk.AfterCardsMove, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
        if target == player and data.name == "nya__play" then
          return player.room:getTag("RoundCount")  --防止游戏开始添加技能时触发
        end
      elseif event == fk.EventLoseSkill then
        return target == player and data.name == "nya__play"
      elseif player:getHandcardNum() < math.max(player:getLostHp(), 1) then
        if event == fk.AfterCardsMove then
          for _, move in ipairs(data) do
            return move.from == player.id
          end
        elseif event == fk.HpChanged or event == fk.MaxHpChanged then
          return target == player
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      player.room:changeMaxHp(player, -1)
    elseif event == fk.EventLoseSkill then
      player.room:changeMaxHp(player, 1)
    else
      player:drawCards(math.max(player:getLostHp(), 1) - player:getHandcardNum(), self.name)
    end
  end,
}
zhangchunhua:addSkill(nya__jueqing)
zhangchunhua:addSkill(nya__shangshi)
zhangchunhua:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__zhangchunhua"] = "春华喵",
  ["nya__jueqing"] = "绝情",
  [":nya__jueqing"] = "当你即将造成伤害时，你可以失去等量体力，令此伤害翻倍。你即将造成的伤害视为体力流失。",
  ["nya__shangshi"] = "伤逝",
  [":nya__shangshi"] = "当你的手牌数小于X时，你将手牌摸至X张（X为你已损失体力值，至少为1）；当你失去〖逗猫〗时，你加1点体力上限；当你获得〖逗猫〗时，"..
  "你减1点体力上限。",
  ["#nya__jueqing-invoke"] = "绝情：你可以失去%arg点体力，令你对 %dest 造成的伤害翻倍",
}

local wangyi = General(extension, "nya__wangyi", "wei", 4, 4, General.Female)
local nya__zhenlie = fk.CreateTriggerSkill{
  name = "nya__zhenlie",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (data.card:isCommonTrick() or data.card.trueName == "slash")
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#nya__zhenlie-invoke"
    if not player:hasSkill("nya__play", true) then
      prompt = "#nya__zhenlie2-invoke"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt.."::"..data.from..":"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if player.dead then return end
    table.insertIfNeed(data.nullifiedTargets, player.id)
    local to = room:getPlayerById(data.from)
    if to.dead or to:isNude() then return end
    room:doIndicate(player.id, {data.from})
    local id = room:askForCardChosen(player, to, "he", self.name)
    if not player:hasSkill("nya__play", true) then
      room:obtainCard(player, id, false, fk.ReasonPrey)
    else
      room:throwCard({id}, self.name, to, player)
    end
  end,
}
local nya__miji = fk.CreateTriggerSkill{
  name = "nya__miji",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Finish then
      if not player:hasSkill("nya__play", true) then
        return table.find(player.room.alive_players, function(p) return p:isWounded() end)
      else
        return player:isWounded()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getLostHp()
    if not player:hasSkill("nya__play", true) then
      n = math.max(table.unpack(table.map(room.alive_players, function(p) return p:getLostHp() end)))
    end
    player:drawCards(n, self.name)
    if not player.dead and player:getHandcardNum() >= n then
      room:setPlayerMark(player, self.name, n)
      local success, dat = room:askForUseActiveSkill(player, "nya__miji_active", "#nya__miji-give:::"..n, true)
      room:setPlayerMark(player, self.name, 0)
      if success then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(dat.cards)
        room:obtainCard(dat.targets[1], dummy, false, fk.ReasonGive)
      end
    end
  end,
}
local nya__miji_active = fk.CreateActiveSkill{
  name = "nya__miji_active",
  mute = true,
  card_num = function()
    return Self:getMark("nya__miji")
  end,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected < Self:getMark("nya__miji") and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
}
Fk:addSkill(nya__miji_active)
wangyi:addSkill(nya__zhenlie)
wangyi:addSkill(nya__miji)
wangyi:addSkill("nya__play")
Fk:loadTranslationTable{
  ["nya__wangyi"] = "王异喵",
  ["nya__zhenlie"] = "贞烈",
  [":nya__zhenlie"] = "当你成为【杀】或普通锦囊牌的目标后，你可以失去1点体力使此牌对你无效，然后你弃置使用者一张牌；若你没有〖逗猫〗，"..
  "则改为获得使用者一张牌。",
  ["nya__miji"] = "秘计",
  [":nya__miji"] = "结束阶段，你可以摸至多X张牌（X为你已损失的体力值），然后你可以将等量的手牌交给一名其他角色；若你没有〖逗猫〗，"..
  "X改为场上已损失体力值最多的角色的已损失体力值且至多为5。",
  ["#nya__zhenlie-invoke"] = "贞烈：%dest 对你使用%arg，你可以失去1点体力令此牌对你无效，然后弃置其一张牌",
  ["#nya__zhenlie2-invoke"] = "贞烈：%dest 对你使用%arg，你可以失去1点体力令此牌对你无效，然后获得其一张牌",
  ["#nya__miji-give"] = "秘计：你可以将%arg张手牌交给一名其他角色",
  ["nya__miji_active"] = "秘计",
}

return extension
