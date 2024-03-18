local extension = Package("joy_yj")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_yj"] = "欢乐-一将成名",
}

local U = require "packages/utility/utility"

-- yj2011
local yujin = General(extension, "joy__yujin", "wei", 4)
local yizhong = fk.CreateTriggerSkill{
  name = "joy__yizhong",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "slash" and player.id == data.to and
      data.card.suit == Card.Club and #player.player_cards[Player.Equip] == 0
  end,
  on_use = Util.TrueFunc,
}
yujin:addSkill(yizhong)
yujin:addSkill("ty_ex__zhenjun")
Fk:loadTranslationTable{
  ["joy__yujin"] = "于禁",
  ["joy__yizhong"] = "毅重",
  [":joy__yizhong"] = "锁定技，若你的装备区没有牌，梅花【杀】对你无效。",
}

local caozhi = General(extension, "joy__caozhi", "wei", 3)
local luoying = fk.CreateTriggerSkill{
  name = "joy__luoying",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local ids = {}
      local room = player.room
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.moveReason == fk.ReasonDiscard and move.from and move.from ~= player.id then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              Fk:getCardById(info.cardId).suit == Card.Club and
              room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          elseif move.moveReason == fk.ReasonJudge then
            local judge_event = room.logic:getCurrentEvent():findParent(GameEvent.Judge)
            if judge_event and judge_event.data[1].who ~= player then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.Processing and Fk:getCardById(info.cardId).suit == Card.Club and
                room:getCardArea(info.cardId) == Card.DiscardPile then
                  table.insertIfNeed(ids, info.cardId)
                end
              end
            end
          end
        end
      end
      ids = U.moveCardsHoldingAreaCheck(room, ids)
      if #ids > 0 then
        self.cost_data = ids
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = table.simpleClone(self.cost_data)
    if #ids > 1 then
      local cards, _ = U.askforChooseCardsAndChoice(player, ids, {"OK"}, self.name,
      "#joy__luoying-choose", {"joy__get_all"}, 1, #ids)
      if #cards > 0 then
        ids = cards
      end
    end
    room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonPrey, self.name)
  end,
}
local luoying_maxcards = fk.CreateMaxCardsSkill{
  name = "#luoying_maxcards",
  exclude_from = function(self, player, card)
    return player:hasSkill("joy__luoying") and card.suit == Card.Club
  end,
}
local jiushi = fk.CreateViewAsSkill{
  name = "joy__jiushi",
  anim_type = "support",
  prompt = "#joy__jiushi-active",
  pattern = "analeptic",
  card_filter = Util.FalseFunc,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self)
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function (self, player)
    return player.faceup
  end,
  enabled_at_response = function (self, player)
    return player.faceup
  end,
}
local jiushi_trigger = fk.CreateTriggerSkill{
  name = "#joy__jiushi_trigger",
  mute = true,
  main_skill = jiushi,
  events = {fk.Damaged, fk.TurnedOver},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.Damaged then
        return (data.extra_data or {}).jiushi_check
      elseif event == fk.TurnedOver then
        return player:hasSkill(jiushi)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return event == fk.TurnedOver or player.room:askForSkillInvoke(player, jiushi.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(jiushi.name)
    if event == fk.Damaged then
      room:notifySkillInvoked(player, jiushi.name, "defensive")
      player:turnOver()
    elseif event == fk.TurnedOver and not player.dead then
      room:notifySkillInvoked(player, jiushi.name, "drawcard")
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick")
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name)
      end
    end
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiushi) and not player.faceup
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.jiushi_check = true
  end,
}
luoying:addRelatedSkill(luoying_maxcards)
jiushi:addRelatedSkill(jiushi_trigger)
caozhi:addSkill(luoying)
caozhi:addSkill(jiushi)
Fk:loadTranslationTable{
  ["joy__caozhi"] = "曹植",
  ["#joy__caozhi"] = "八斗之才",

  ["joy__luoying"] = "落英",
  [":joy__luoying"] = "①当其他角色的牌因弃置或判定进入弃牌堆后，你可以获得之；②你的梅花牌不计入手牌上限。",
  ["joy__jiushi"] = "酒诗",
  [":joy__jiushi"] = "①若你的武将牌正面朝上，你可以翻面视为使用一张【酒】；<br>②当你受到伤害时，若你的武将牌背面朝上，你可以在受到伤害后翻至正面;<br>③当你翻面时，你获得牌堆中的一张随机锦囊牌。",
  ["#joy__jiushi_trigger"] = "酒诗",
  ["#joy__jiushi-active"] = "酒诗：你可以翻到背面视为使用一张【酒】",

  ["#joy__luoying-choose"] = "落英：选择要获得的牌",
  ["joy__get_all"] = "全部获得",
}

local wuguotai = General(extension, "joy__wuguotai", "wu", 3, 3, General.Female)
local ganlu = fk.CreateTriggerSkill{
  name = "joy__ganlu",
  events = {fk.EventPhaseStart},
  anim_type = "control",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local _,dat = room:askForUseActiveSkill(player, "joy__ganlu_active", "#joy__ganlu-invoke", true)
    if dat then
      local targets = table.map(dat.targets, Util.Id2PlayerMapper)
      if dat.interaction == "joy__ganlu_move" then
        room:askForMoveCardInBoard(player, targets[1], targets[2], self.name, "e", nil)
      else
        local slots = {}
        for _, id in ipairs(targets[1]:getCardIds("e")) do
          local s = Fk:getCardById(id).sub_type
          if targets[2]:getEquipment(s) ~= nil then
            table.insertIfNeed(slots, Util.convertSubtypeAndEquipSlot(s))
          end
        end
        if #slots == 0 then return end
        local choice = room:askForChoice(player, slots, self.name)
        local id1 = targets[1]:getEquipment(Util.convertSubtypeAndEquipSlot(choice))
        local id2 = targets[2]:getEquipment(Util.convertSubtypeAndEquipSlot(choice))
        local moveInfos = {}
        table.insert(moveInfos, {
          from = targets[1].id,
          ids = {id1},
          toArea = Card.Processing,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = self.name,
        })
        table.insert(moveInfos, {
          from = targets[2].id,
          ids = {id2},
          toArea = Card.Processing,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = self.name,
        })
        room:moveCards(table.unpack(moveInfos))
        moveInfos = {}
        if not targets[2].dead and room:getCardArea(id1) == Card.Processing
        and targets[2]:hasEmptyEquipSlot(Fk:getCardById(id1).sub_type) then
          table.insert(moveInfos, {
            ids = {id1},
            to = targets[2].id,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonExchange,
            proposer = player.id,
            skillName = self.name,
          })
        end
        if not targets[1].dead and room:getCardArea(id2) == Card.Processing
        and targets[1]:hasEmptyEquipSlot(Fk:getCardById(id2).sub_type) then
          table.insert(moveInfos, {
            ids = {id2},
            to = targets[1].id,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonExchange,
            proposer = player.id,
            skillName = self.name,
          })
        end
        if #moveInfos > 0 then
          room:moveCards(table.unpack(moveInfos))
        end
        local to_throw = {}
        if room:getCardArea(id1) == Card.Processing then table.insert(to_throw, id1) end
        if room:getCardArea(id2) == Card.Processing then table.insert(to_throw, id2) end
        if #to_throw > 0 then
          room:moveCards({
            ids = to_throw,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
          })
        end
      end
    else
      player:drawCards(1, self.name)
    end
  end,
}
local joy__ganlu_active = fk.CreateActiveSkill{
  name = "joy__ganlu_active",
  card_num = 0,
  target_num = 2,
  interaction = function(self)
    return UI.ComboBox {choices = {"joy__ganlu_move", "joy__ganlu_exchange"} }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if not self.interaction.data or #selected == 2 then return end
    local to = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return #to:getCardIds("e") > 0
    else
      local first = Fk:currentRoom():getPlayerById(selected[1])
      if #first:getCardIds("e") == 0 or firse == to then return end
      if self.interaction.data == "joy__ganlu_move" then
        return first:canMoveCardsInBoardTo(to, "e")
      else
        return table.find(first:getCardIds("e"), function(id) return to:getEquipment(Fk:getCardById(id).sub_type) ~= nil end)
      end
    end
  end,
}
Fk:addSkill(joy__ganlu_active)
wuguotai:addSkill(ganlu)
local buyi = fk.CreateTriggerSkill{
  name = "joy__buyi",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) <3
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#joy__buyi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards({id})
    if Fk:getCardById(id).type == Card.TypeBasic and table.contains(target.player_cards[Player.Hand], id) then
      room:throwCard({id}, self.name, target, target)
      if target.dead or not target:isWounded() then return end
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,
}
wuguotai:addSkill(buyi)
Fk:loadTranslationTable{
  ["joy__wuguotai"] = "吴国太",
  ["#joy__wuguotai"] = "武烈皇后",

  ["joy__ganlu"] = "甘露",
  [":joy__ganlu"] = "锁定技，出牌阶段开始时，你须选择一项：1.移动场上的一张装备牌；2.交换两名角色装备区副类别相同的装备牌；3.你摸一张牌。",
  ["joy__buyi"] = "补益",
  [":joy__buyi"] = "每回合限三次，当一名角色进入濒死状态时，你可以展示该角色一张手牌，若为基本牌，则其弃置此牌并回复1点体力。",

  ["#joy__ganlu-invoke"] = "甘露：请移动或交换场上装备牌，点“取消”则摸一张牌",
  ["joy__ganlu_active"] = "甘露",
  ["joy__ganlu_move"] = "移动场上的一张装备牌",
  ["joy__ganlu_exchange"] = "交换两名角色副类别相同的装备牌",
  ["#joy__buyi-invoke"] = "补益：你可以展示 %dest 的一张手牌，若为基本牌，其弃置并回复1点体力",
}

-- yj2012

local xunyou = General(extension, "joy__xunyou", "wei", 3)
local joy__qice = fk.CreateViewAsSkill{
  name = "joy__qice",
  prompt = "#joy__qice",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and card.skill:canUse(Self, card) then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  view_as = function(self, cards)
    if #cards == 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
}
local joy__zhiyu = fk.CreateTriggerSkill{
  name = "joy__zhiyu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, self.name)
    if not player.dead and not player:isKongcheng() then
      room:askForDiscard(player, 1, 1, false, self.name, false)
    end
    local cards = table.simpleClone(player:getCardIds("h"))
    player:showCards(cards)
    if player.dead or not data.from or data.from.dead or data.from:getHandcardNum() <= player:getHandcardNum() then return end
    if table.every(cards, function(id) return #cards == 0 or Fk:getCardById(id).color == Fk:getCardById(cards[1]).color end) and
      room:askForSkillInvoke(player, self.name, nil, "#joy__zhiyu-discard::"..data.from.id) then
      room:doIndicate(player.id, {data.from.id})
      local n = data.from:getHandcardNum() - player:getHandcardNum()
      room:askForDiscard(data.from, n, n, false, self.name, false)
    end
  end,
}
xunyou:addSkill(joy__qice)
xunyou:addSkill(joy__zhiyu)
Fk:loadTranslationTable{
  ["joy__xunyou"] = "荀攸",
  ["joy__qice"] = "奇策",
  [":joy__qice"] = "出牌阶段限一次，你可以将任意张手牌当任意一张普通锦囊牌使用。",
  ["joy__zhiyu"] = "智愚",
  [":joy__zhiyu"] = "当你受到伤害后，你可以摸两张牌并弃置一张牌，然后展示所有手牌，若颜色均相同，你可以令伤害来源将手牌弃至与你相同。",
  ["#joy__qice"] = "奇策：你可以将任意张手牌当一张普通锦囊牌使用",
  ["#joy__zhiyu-discard"] = "智愚：你可以令 %dest 将手牌弃至与你相同",
}

local fuhuanghou = General(extension, "joy__fuhuanghou", "qun", 3, 3, General.Female)
local joy__zhuikong = fk.CreateTriggerSkill{
  name = "joy__zhuikong",
  anim_type = "control",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and not player:isKongcheng() and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#joy__zhuikong-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      room:setPlayerMark(target, "joy__zhuikong_prohibit-turn", 1)
    else
      room:setPlayerMark(player, "joy__zhuikong-turn", 1)
    end
  end
}
local joy__zhuikong_prohibit = fk.CreateProhibitSkill{
  name = "#joy__zhuikong_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("joy__zhuikong_prohibit-turn") > 0 and from ~= to
  end,
}
local joy__zhuikong_distance = fk.CreateDistanceSkill{
  name = "#joy__zhuikong_distance",
  fixed_func = function(self, from, to)
    if to:usedSkillTimes("joy__zhuikong", Player.HistoryTurn)> 0 and to:getMark("joy__zhuikong-turn") > 0 then
      return 1
    end
  end,
}
local joy__qiuyuan = fk.CreateTriggerSkill{
  name = "joy__qiuyuan",
  anim_type = "control",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.id ~= data.from end), function (p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 1, 3, "#joy__qiuyuan-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:sortPlayersByAction(self.cost_data)
    room:doIndicate(player.id, self.cost_data)
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local yes = true
        if not player.dead then
          local card = room:askForCard(p, 1, 1, false, self.name, true, "jink", "#joy__qiuyuan-give:"..player.id.."::"..data.card:toLogString())
          if #card > 0 then
            room:obtainCard(player.id, card[1], true, fk.ReasonGive)
            yes = false
          end
        end
        if yes then
          TargetGroup:pushTargets(data.targetGroup, id)
          if not p:isNude() then
            room:askForDiscard(p, 1, 1, true, self.name, false)
          end
        end
      end
    end
  end,
}
joy__zhuikong:addRelatedSkill(joy__zhuikong_prohibit)
joy__zhuikong:addRelatedSkill(joy__zhuikong_distance)
fuhuanghou:addSkill(joy__zhuikong)
fuhuanghou:addSkill(joy__qiuyuan)
Fk:loadTranslationTable{
  ["joy__fuhuanghou"] = "伏皇后",
  ["joy__zhuikong"] = "惴恐",
  [":joy__zhuikong"] = "其他角色回合开始时，你可以与其拼点：若你赢，其本回合不能对除其以外的角色使用牌；若你没赢，本回合其与你的距离视为1。",
  ["joy__qiuyuan"] = "求援",
  [":joy__qiuyuan"] = "当你成为【杀】的目标时，你可以令除使用者以外至多三名角色依次选择一项：1.交给你一张【闪】；2.成为此【杀】的目标并弃置一张牌。",
  ["#joy__zhuikong-invoke"] = "惴恐：你可以与 %dest 拼点，若赢则其本回合不能对除其以外的角色使用牌",
  ["#joy__qiuyuan-choose"] = "求援：你可以令至多三名角色选择：交给你一张【闪】，或成为此【杀】的目标并弃置一张牌",
  ["#joy__qiuyuan-give"] = "求援：你需交给 %src 一张【闪】，否则你也成为此%arg目标并弃置一张牌",
}

local sundeng = General(extension, "joy__sundeng", "wu", 4)
local joy__kuangbi = fk.CreateActiveSkill{
  name = "joy__kuangbi",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#joy__kuangbi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askForCard(target, 1, 3, true, self.name, false, ".", "#joy__kuangbi-card:"..player.id)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    player:addToPile(self.name, dummy, false, self.name)
    if player.dead or target.dead then return end
    if room:askForSkillInvoke(player, self.name, nil, "#joy__kuangbi-draw::"..target.id..":"..#dummy.subcards) then
      target:drawCards(#dummy.subcards, self.name)
    end
  end,
}
local joy__kuangbi_trigger = fk.CreateTriggerSkill {
  name = "#joy__kuangbi_trigger",
  mute = true,
  events = {fk.TurnStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return target == player and #player:getPile("joy__kuangbi") > 0
    elseif player:hasSkill("joy__kuangbi") and (table.every(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@joy__kuangbi") == 0 end)) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.extra_data and move.extra_data.joy__kuangbi then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("joy__kuangbi")
    room:notifySkillInvoked(player, "joy__kuangbi", "support")
    if event == fk.TurnStart then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(player:getPile("joy__kuangbi"))
      for _, id in ipairs(player:getPile("joy__kuangbi")) do
        room:setCardMark(Fk:getCardById(id), "@@joy__kuangbi", 1)
      end
      room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    else
      player:drawCards(1, "joy__kuangbi")
      if player:isWounded() and not player.dead then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = "joy__kuangbi",
        }
      end
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill("joy__kuangbi") then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@joy__kuangbi") > 0 then
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
        local yes = false
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@joy__kuangbi") > 0 then
            player.room:setCardMark(Fk:getCardById(info.cardId), "@@joy__kuangbi", 0)
            yes = true
          end
        end
        if yes then
          move.extra_data = move.extra_data or {}
          move.extra_data.joy__kuangbi = true
        end
      end
    end
  end,
}
joy__kuangbi:addRelatedSkill(joy__kuangbi_trigger)
sundeng:addSkill(joy__kuangbi)
Fk:loadTranslationTable{
  ["joy__sundeng"] = "孙登",
  ["joy__kuangbi"] = "匡弼",
  [":joy__kuangbi"] = "出牌阶段限一次，你可以令一名其他角色将其一至三张牌置于你的武将牌上，然后你可令其摸等量的牌。你的回合开始时，"..
  "你获得武将牌上的所有牌。当你失去手牌中最后一张“匡弼”牌时，你摸一张牌并回复1点体力。",
  ["#joy__kuangbi"] = "匡弼：令一名角色将至多三张牌置为“匡弼”牌，你可以令其摸等量牌，你回合开始时获得“匡弼”牌",
  ["#joy__kuangbi-card"] = "匡弼：将至多三张牌置为 %src 的“匡弼”牌",
  ["#joy__kuangbi-draw"] = "匡弼：是否令 %dest 摸%arg张牌？",
  ["@@joy__kuangbi"] = "匡弼",
}

local joy__guanping = General(extension, "joy__guanping", "shu", 4)
local joy__longyin = fk.CreateTriggerSkill{
  name = "joy__longyin",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#joy__longyin-invoke::"..target.id, true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    if not data.extraUse then
      data.extraUse = true
      target:addCardUseHistory(data.card.trueName, -1)
    end
    if data.card.color == Card.Red and not player.dead then
      player:drawCards(1, self.name)
    end
    if data.card.suit == Fk:getCardById(self.cost_data[1]).suit and player:usedSkillTimes("joy__jiezhong", Player.HistoryGame) > 0 then
      player:setSkillUseHistory("joy__jiezhong", 0, Player.HistoryGame)
    end
  end,
}
local joy__jiezhong = fk.CreateTriggerSkill{
  name = "joy__jiezhong",
  anim_type = "drawcard",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      player.maxHp > player:getHandcardNum() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local draw = player.maxHp - player:getHandcardNum()
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__jiezhong-invoke:::"..draw)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player.maxHp - player:getHandcardNum()
    player:drawCards(n, self.name)
  end,
}
joy__guanping:addSkill(joy__longyin)
joy__guanping:addSkill(joy__jiezhong)
Fk:loadTranslationTable{
  ["joy__guanping"] = "关平",
  ["#joy__guanping"] = "忠臣孝子",

  ["joy__longyin"] = "龙吟",
  [":joy__longyin"] = "每当一名角色在其出牌阶段使用【杀】时，你可以弃置一张牌令此【杀】不计入出牌阶段使用次数，若此【杀】为红色，你摸一张牌。"..
  "若你以此法弃置的牌花色与此【杀】相同，你重置〖竭忠〗。",
  ["#joy__longyin-invoke"] = "龙吟：你可以弃置一张牌令 %dest 的【杀】不计入次数限制",
  ["joy__jiezhong"] = "竭忠",
  [":joy__jiezhong"] = "限定技，出牌阶段开始时，若你的手牌数小于体力上限，你可以将手牌补至体力上限。",
  ["#joy__jiezhong-invoke"] = "竭忠：是否发动“竭忠”摸%arg张牌？ ",

}

local joy__xushu = General(extension, "joy__xushu", "shu", 3)
local joy__jujian = fk.CreateTriggerSkill{
  name = "joy__jujian",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Finish or player.phase == Player.Start)and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, id = player.room:askForChooseCardAndPlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, ".|.|.|.|.|^basic", "#joy__jujian-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos[1], id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:throwCard({self.cost_data[2]}, self.name, player, player)
    local choices = {"draw2"}
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    if not to.faceup or to.chained then
      table.insert(choices, "joy__jujian_reset")
    end
    local choice = room:askForChoice(to, choices, self.name, nil, false, {"draw2", "recover", "joy__jujian_reset"})
    if choice == "draw2" then
      to:drawCards(2, self.name)
    elseif choice == "recover" then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    else
      to:reset()
    end
  end,
}
joy__xushu:addSkill("wuyan")
joy__xushu:addSkill(joy__jujian)
Fk:loadTranslationTable{
  ["joy__xushu"] = "徐庶",
  ["#joy__xushu"] = "忠孝的侠士",

  ["joy__jujian"] = "举荐",
  [":joy__jujian"] = "准备或结束阶段，你可以弃置一张非基本牌，令一名角色选择一项：摸两张牌；回复1点体力；复原武将牌。",
  ["#joy__jujian-choose"] = "举荐：你可以弃置一张非基本牌，令一名角色选择摸俩张牌/回复体力/复原武将牌",
  ["joy__jujian_reset"] = "复原武将牌",

}

local joyex__liaohua = General(extension, "joyex__liaohua", "shu", 4)
local joyex__dangxian = fk.CreateTriggerSkill{
  name = "joyex__dangxian",
  anim_type = "offensive",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local cards = player.room:getCardsFromPileByRule("slash", 1)
    if #cards > 0 then
      player.room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
    end
    player:gainAnExtraPhase(Player.Play)
  end,
}
local joyex__fuli = fk.CreateTriggerSkill{
  name = "joyex__fuli",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 1)
    local kingdoms = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    room:recover({
      who = player,
      num = math.min(#kingdoms, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    if player:getHandcardNum() < #kingdoms and not player.dead then
      player:drawCards(#kingdoms - player:getHandcardNum())
    end
    if #kingdoms > 3 and not player.dead then
      player:turnOver()
    end
  end,
}
joyex__liaohua:addSkill(joyex__dangxian)
joyex__liaohua:addSkill(joyex__fuli)
Fk:loadTranslationTable{
  ["joyex__liaohua"] = "界廖化",
  ["#joyex__liaohua"] = "历尽沧桑",

  ["joyex__dangxian"] = "当先",
  [":joyex__dangxian"] = "回合开始时你进行一个额外的出牌阶段并摸一张【杀】。",
  ["joyex__fuli"] = "伏枥",
  [":joyex__fuli"] = "限定技，当你处于濒死状态时，你可以将体力回复至X点且手牌摸至X张（X为全场势力数）"..
  "若X大于3，你翻面。",

}

local caoxiu = General(extension, "joy__caoxiu", "wei", 4)
local joy__qingxi = fk.CreateTriggerSkill{
  name = "joy__qingxi",
  events = {fk.TargetSpecified},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.trueName == "duel")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if player:inMyAttackRange(p) then
        n = n + 1
      end
    end
    local max_num = #player:getEquipments(Card.SubtypeWeapon) > 0 and 4 or 2
    n = math.min(n, max_num)
    if player.room:askForSkillInvoke(player, self.name, data, "#joy__qingxi::" .. data.to..":"..n) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local num = self.cost_data
    if #room:askForDiscard(to, num, num, false, self.name, true, ".", "#joy__qingxi-discard:::"..num) == num then
      local weapon = player:getEquipments(Card.SubtypeWeapon)
      if #weapon > 0 then
        room:throwCard(weapon, self.name, player, to)
      end
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.ty_ex__qingxi = data.to
      local judge = {
        who = player,
        reason = self.name,
        pattern = ".|.|club,spade,heart,diamond",
      }
      room:judge(judge)
      if judge.card.color == Card.Red then
        data.disresponsive = true
      elseif judge.card.color == Card.Black and not player.dead then
        player:drawCards(2,self.name)
      end
    end
  end,
}
local joy__qingxi_delay = fk.CreateTriggerSkill{
  name = "#joy__qingxi_delay",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data[1]
        if use.extra_data and use.extra_data.ty_ex__qingxi == data.to.id then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
joy__qingxi:addRelatedSkill(joy__qingxi_delay)
caoxiu:addSkill("qianju")
caoxiu:addSkill(joy__qingxi)
Fk:loadTranslationTable{
  ["joy__caoxiu"] = "界曹休",
  ["#joy__caoxiu"] = "千里骐骥",

  ["joy__qingxi"] = "倾袭",
  [":joy__qingxi"] = "当你使用【杀】或【决斗】指定一名角色为目标后，你可以令其选择一项："..
  "1.弃置等同于你攻击范围内的角色数张手牌（至多为2，若你武器区里有武器牌则改为至多为4），然后弃置你装备区里的武器牌；"..
  "2.令此牌对其造成的基础伤害值+1且你进行一次判定，若结果为红色，该角色不能响应此牌;若结果为黑色，你摸两张牌",
  ["#joy__qingxi"] = "倾袭：可令 %dest 选一项：1.弃 %arg 张手牌并弃置你的武器；2.伤害+1且你判定，为红不能响应，为黑摸两张牌",
  ["#joy__qingxi-discard"] = "倾袭：你需弃置 %arg 张手牌，否则伤害+1且其判定，结果为红你不能响应,结果为黑其摸两张牌",

}

local caorui = General(extension, "joy__caorui", "wei", 3)
local mingjian = fk.CreateActiveSkill{
  name = "joy__mingjian",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = effect.cards
    local dummy = Fk:cloneCard("dilu")
    room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false)
    room:addPlayerMark(target, "@@" .. self.name, 1)
  end,
}
local mingjian_record = fk.CreateTriggerSkill{
  name = "#joy__mingjian_record",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@joy__mingjian") > 0 and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@@joy__mingjian-turn", player:getMark("@@joy__mingjian"))
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, player:getMark("@@joy__mingjian"))
    room:setPlayerMark(player, "@@joy__mingjian", 0)
  end,
}
local mingjian_targetmod = fk.CreateTargetModSkill{
  name = "#joy__mingjian_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@joy__mingjian-turn") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@@joy__mingjian-turn")
    end
  end,
}
local xingshuai = fk.CreateTriggerSkill{
  name = "joy__xingshuai$",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      not table.every(player.room:getOtherPlayers(player), function(p) return p.kingdom ~= "wei" end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "wei" and room:askForSkillInvoke(p, self.name, data, "#joy__xingshuai-invoke::"..player.id) then
        table.insert(targets, p)
      end
    end
    if #targets > 0 then
      for _, p in ipairs(targets) do
        room:recover{
          who = player,
          num = 1,
          recoverBy = p,
          skillName = self.name
        }
      end
    end
    if not player.dying then
      for _, p in ipairs(targets) do
        room:damage{
          to = p,
          damage = 1,
          skillName = self.name,
        }
        if not p.dead then
            room:drawCards(p,1,self.name)
        end
      end
    end
  end,
}
mingjian:addRelatedSkill(mingjian_record)
mingjian:addRelatedSkill(mingjian_targetmod)
caorui:addSkill("huituo")
caorui:addSkill(mingjian)
caorui:addSkill(xingshuai)
Fk:loadTranslationTable{
  ["joy__caorui"] = "曹叡",

  ["joy__mingjian"] = "明鉴",
  [":joy__mingjian"] = "出牌阶段限一次，你可以将任意张手牌交给一名其他角色，然后该角色下回合的手牌上限+1，且出牌阶段内可以多使用一张【杀】。",
  ["joy__xingshuai"] = "兴衰",
  [":joy__xingshuai"] = "主公技，限定技，当你进入濒死状态时，你可令其他魏势力角色依次选择是否令你回复1点体力。选择是的角色在此次濒死结算结束后"..
  "受到1点无来源的伤害并摸一张牌。",

  ["@@joy__mingjian"] = "明鉴",
  ["@@joy__mingjian-turn"] = "明鉴",
  ["#joy__xingshuai-invoke"] = "兴衰：你可以令%dest回复1点体力，结算后你受到1点伤害并摸一张牌",

}

local xushi = General(extension, "joy__xushi", "wu", 3, 3, General.Female)
local wengua = fk.CreateActiveSkill{
  name = "joy__wengua",
  anim_type = "support",
  card_num = 1,
  target_num = 0,
  prompt = "#wengua",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local choices = {"Cancel", "Top", "Bottom"}
    local id = effect.cards[1]
    local card = Fk:getCardById(id)
    player:showCards(id)
    if card.type == Card.TypeTrick then
      if player.maxHp < 5 then
        room:changeMaxHp(player, 1)
      end
      if player:isWounded() then
        player.room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
          })
      end
    end
    local choice = room:askForChoice(player, choices, self.name,
      "#wengua-choice::"..player.id..":"..Fk:getCardById(effect.cards[1]):toLogString())
    if choice == "Cancel" then return end
    local index = 1
    if choice == "Bottom" then
      index = -1
    end
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      drawPilePosition = index,
    })
    if player.dead then return end
    if choice == "Top" then
      player:drawCards(1, self.name, "bottom")
      if not player.dead then
        player:drawCards(1, self.name, "bottom")
      end
    else
      player:drawCards(1, self.name)
      if not player.dead then
        player:drawCards(1, self.name)
      end
    end
  end,
}
local wengua_trigger = fk.CreateTriggerSkill{
  name = "#joy__wengua_trigger",

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self and not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill("joy__wengua", true) end)
    else
      return target == player and player:hasSkill(self.name, true, true) and
        not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill("joy__wengua", true) end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self.name, true) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:handleAddLoseSkills(p, "joy__wengua&", nil, false, true)
        end
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:handleAddLoseSkills(p, "-joy__wengua&", nil, false, true)
      end
    end
  end,
}
local wengua_active = fk.CreateActiveSkill{
  name = "joy__wengua&",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#wengua&",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):hasSkill("joy__wengua")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = effect.cards[1]
    local card = Fk:getCardById(id)
    player:showCards(id)
    room:obtainCard(target.id, id, false, fk.ReasonGive)
    if card.type == Card.TypeTrick then
      if target.maxHp < 5 then
        room:changeMaxHp(target, 1)
      end
      if target:isWounded() then
        target.room:recover({
          who = target,
          num = 1,
          recoverBy = target,
          skillName = self.name
          })
      end
    end
    if room:getCardOwner(id) ~= target or room:getCardArea(id) ~= Card.PlayerHand then return end
    local choices = {"Cancel", "Top", "Bottom"}
    local choice = room:askForChoice(target, choices, "wengua",
      "#wengua-choice::"..player.id..":"..Fk:getCardById(id):toLogString())
    if choice == "Cancel" then return end
    local index = 1
    if choice == "Bottom" then
      index = -1
    end
    room:moveCards({
      ids = effect.cards,
      from = target.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = "wengua",
      drawPilePosition = index,
    })
    if player.dead then return end
    if choice == "Top" then
      player:drawCards(1, "wengua", "bottom")
      if not target.dead then
        target:drawCards(1, "wengua", "bottom")
      end
    else
      player:drawCards(1, "wengua")
      if not target.dead then
        target:drawCards(1, "wengua")
      end
    end
  end,
}
local fuzhu = fk.CreateTriggerSkill{
  name = "joy__fuzhu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Finish and
        #player.room.draw_pile <= 10 * player.maxHp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#fuzhu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local n = 0
    local cards = table.simpleClone(room.draw_pile)
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id, true)
      if card.trueName == "slash" then
        room:useCard({
          from = player.id,
          tos = {{target.id}},
          card = card,
        })
        n = n + 1
      end
      if n >= #room.players or player.dead or target.dead then
        break
      end
    end
    room:shuffleDrawPile()
  end,
}
Fk:addSkill(wengua_active)
wengua:addRelatedSkill(wengua_trigger)
xushi:addSkill(wengua)
xushi:addSkill(fuzhu)
Fk:loadTranslationTable{
  ["joy__xushi"] = "徐氏",
  ["joy__wengua"] = "问卦",
  [":joy__wengua"] = "每名角色出牌阶段限一次，其可以交给你一张牌并展示，若该牌为锦囊牌，则你加一点体力上限（不会超过5）并回复一点体力,"..
  "然后你可以将此牌置于牌堆顶或牌堆底，你与其从另一端摸一张牌。",
  ["joy__fuzhu"] = "伏诛",
  [":joy__fuzhu"] = "一名角色结束阶段，若牌堆剩余牌数不大于你体力值的十倍，你可以依次对其使用牌堆中所有的【杀】（不能超过游戏人数），然后洗牌。",
  ["#joy__wengua"] = "问卦：你可以将一张牌置于牌堆顶或牌堆底，从另一端摸两张牌",
  ["joy__wengua&"] = "问卦",
  [":joy__wengua&"] = "出牌阶段限一次，你可以交给徐氏一张牌并展示之，若该牌为锦囊牌，则其加一点体力上限（不会超过5）并回复一点体力,"..
  "然后其可以将此牌置于牌堆顶或牌堆底，其与你从另一端摸一张牌。",
}

return extension
