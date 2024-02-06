local extension = Package("joy_ex")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_ex"] = "欢乐-界限突破",
  ["joyex"] = "欢乐界",
}

--其实有些并非界限突破，单纯加强的放这里
--曹操 司马懿 张辽
--刘备 黄月英 
--孙权 甘宁 吕蒙
--华佗 貂蝉 华雄 公孙瓒
--
--典韦 卧龙
--曹丕 徐晃 神吕布
--张郃 神司马懿
--王基 严颜 陆抗
local huangyueying = General(extension, "joyex__huangyueying", "shu", 3, 3, General.Female)
local joyex__jizhi = fk.CreateTriggerSkill{
  name = "joyex__jizhi",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.type == Card.TypeTrick
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(player:drawCards(1)[1])
    if card.type == Card.TypeBasic and player.phase == Player.Play then
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 1)
    elseif card.type == Card.TypeEquip and room:getCardOwner(card) == player and room:getCardArea(card) == Player.Hand then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return p:hasEmptyEquipSlot(card.sub_type) end), function(p) return p.id end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#joyex__jizhi-choose:::"..card:toLogString(), self.name, true)
      if #to > 0 then
        room:moveCards({
          ids = {card:getEffectiveId()},
          from = player.id,
          to = to[1],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonPut,
          proposer = player.id,
          skillName = self.name,
        })
      end
    elseif card.type == Card.TypeTrick and player.phase == Player.Play then
      room:addPlayerMark(player, "joyex__jizhi-phase", 1)
    end
  end,
}
local joyex__jizhi_targetmod = fk.CreateTargetModSkill{
  name = "#joyex__jizhi_targetmod",
  main_skill = joyex__jizhi,
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("joyex__jizhi-phase") > 0 and scope == Player.HistoryPhase then
      return player:getMark("joyex__jizhi-phase")
    end
    return 0
  end,
}
local joyex__qicai = fk.CreateTriggerSkill{
  name = "joyex__qicai",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.BeforeCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and (player:getEquipment(Card.SubtypeWeapon) or player:getEquipment(Card.SubtypeArmor)) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and (not move.proposer or move.proposer ~= player.id) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and
              table.contains({Card.SubtypeWeapon, Card.SubtypeArmor}, Fk:getCardById(info.cardId).sub_type) then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard and (not move.proposer or move.proposer ~= player.id) then
        local move_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if info.fromArea == Card.PlayerEquip and table.contains({Card.SubtypeWeapon, Card.SubtypeArmor}, Fk:getCardById(id).sub_type) then
            table.insert(ids, id)
          else
            table.insert(move_info, info)
          end
        end
        if #ids > 0 then
          move.moveInfo = move_info
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{
        type = "#cancelDismantle",
        card = ids,
        arg = self.name,
      }
    end
  end,
}
local joyex__qicai_targetmod = fk.CreateTargetModSkill{
  name = "#joyex__qicai_targetmod",
  main_skill = joyex__qicai,
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill("joyex__qicai") and card and card.type == Card.TypeTrick
  end,
}
joyex__jizhi:addRelatedSkill(joyex__jizhi_targetmod)
joyex__qicai:addRelatedSkill(joyex__qicai_targetmod)
huangyueying:addSkill(joyex__jizhi)
huangyueying:addSkill(joyex__qicai)
Fk:loadTranslationTable{
  ["joyex__huangyueying"] = "界黄月英",
  ["joyex__jizhi"] = "集智",
  [":joyex__jizhi"] = "当你使用一张锦囊牌时，你可以摸一张牌，若此牌为：基本牌，你本回合手牌上限+1；装备牌，你可以将之置入一名其他角色装备区；"..
  "锦囊牌，你本阶段使用【杀】次数上限+1。",
  ["joyex__qicai"] = "奇才",
  [":joyex__qicai"] = "锁定技，你使用锦囊牌无距离限制；其他角色不能弃置你装备区里的防具和武器牌。",
  ["#joyex__jizhi-choose"] = "集智：你可以将%arg置入一名其他角色装备区",
}

local diaochan = General(extension, "joyex__diaochan", "qun", 3, 3, General.Female)
local joyex__lijian = fk.CreateActiveSkill{
  name = "joyex__lijian",
  anim_type = "offensive",
  card_num = 1,
  target_num = 2,
  prompt = "#joyex__lijian",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if target:getMark("joyex__lijian-turn") == 0 then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return not target:isProhibited(Fk:currentRoom():getPlayerById(selected[1]), Fk:cloneCard("duel"))
      else
        return false
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    for _, id in ipairs(effect.tos) do
      room:setPlayerMark(room:getPlayerById(id), "joyex__lijian-turn", 1)
    end
    room:useVirtualCard("duel", nil, room:getPlayerById(effect.tos[2]), room:getPlayerById(effect.tos[1]), self.name)
  end,
}
local joyex__biyue = fk.CreateTriggerSkill{
  name = "joyex__biyue",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1 + player:usedSkillTimes("joyex__lijian", Player.HistoryTurn), self.name)
  end,
}
diaochan:addSkill(joyex__lijian)
diaochan:addSkill(joyex__biyue)
Fk:loadTranslationTable{
  ["joyex__diaochan"] = "界貂蝉",
  ["joyex__lijian"] = "离间",
  [":joyex__lijian"] = "出牌阶段限两次，你可以弃置一张牌并选择两名本回合未选择过的角色，视为其中一名角色对另一名角色使用一张【决斗】。",
  ["joyex__biyue"] = "闭月",
  [":joyex__biyue"] = "结束阶段，你摸X张牌（X为本回合你发动〖离间〗次数+1）。",
  ["#joyex__lijian"] = "离间：弃置一张牌，选择两名角色，视为第二名角色对第一名角色使用【决斗】",
}

local xiaoqiao = General(extension, "joyex__xiaoqiao", "wu", 3, 3, General.Female)
local joyex__tianxiang = fk.CreateTriggerSkill{
  name = "joyex__tianxiang",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player
  end,
  on_cost = function(self, event, target, player, data)
    local tar, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, ".|.|heart|hand", "#joyex__tianxiang-choose", self.name, true)
    if #tar > 0 and card then
      self.cost_data = {tar[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:throwCard(self.cost_data[2], self.name, player, player)
    local damage = table.simpleClone(data)
    damage.to = to
    room:damage(damage)
    if not to.dead then
      local n = 1
      if not player.dead then
        local choice = room:askForChoice(player, {"1", tostring(math.min(to:getLostHp(), 5))}, self.name, "#joyex__tianxiang-choice::"..to.id)
        n = tonumber(choice)
      end
      to:drawCards(n, self.name)
    end
    return true
  end,
}
local joyex__hongyan = fk.CreateFilterSkill{
  name = "joyex__hongyan",
  frequency = Skill.Compulsory,
  card_filter = function(self, to_select, player)
    return to_select.suit == Card.Spade and player:hasSkill(self.name)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, to_select.number)
  end,
}
local joyex__hongyan_maxcards = fk.CreateMaxCardsSkill{
  name = "#joyex__hongyan_maxcards",
  frequency = Skill.Compulsory,
  fixed_func = function(self, player)
    if player:hasSkill("joyex__hongyan") and table.find(player:getCardIds("e"), function(id)
      return Fk:getCardById(id).suit == Card.Heart or Fk:getCardById(id).suit == Card.Spade end) then  --FIXME: 耦！
      return player.maxHp
    end
  end
}
joyex__hongyan:addRelatedSkill(joyex__hongyan_maxcards)
xiaoqiao:addSkill(joyex__tianxiang)
xiaoqiao:addSkill(joyex__hongyan)
Fk:loadTranslationTable{
  ["joyex__xiaoqiao"] = "界小乔",
  ["joyex__tianxiang"] = "天香",
  [":joyex__tianxiang"] = "当你受到伤害时，你可以弃置一张<font color='red'>♥</font>手牌，将此伤害转移给一名其他角色，然后你选择一项："..
  "1.其摸一张牌；2.其摸X张牌（X为其已损失体力值且至多为5）。",
  ["joyex__hongyan"] = "红颜",
  [":joyex__hongyan"] = "锁定技，你的♠牌视为<font color='red'>♥</font>牌。若你的装备区有<font color='red'>♥</font>牌，你的手牌上限等于体力上限。",
  ["#joyex__tianxiang-choose" ] = "天香：弃置一张<font color='red'>♥</font>手牌将此伤害转移给一名其他角色，然后令其摸一张牌或X张牌（X为其已损失体力值）",
  ["#joyex__tianxiang-choice"] = "天香：选择令 %dest 摸牌数",
}

local xuhuang = General(extension, "joyex__xuhuang", "wei", 4)
local joyex__duanliang = fk.CreateViewAsSkill{
  name = "joyex__duanliang",
  anim_type = "control",
  pattern = "supply_shortage",
  prompt = "#joyex__duanliang",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and Fk:getCardById(to_select).type ~= Card.TypeTrick
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("supply_shortage")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
}
local joyex__duanliang_targetmod = fk.CreateTargetModSkill{
  name = "#joyex__duanliang_targetmod",
  main_skill = joyex__duanliang,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(self.name) and skill.name == "supply_shortage_skill" and to:getHandcardNum() >= player:getHandcardNum()
  end,
}
local joyex__jiezi = fk.CreateTriggerSkill{
  name = "joyex__jiezi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseSkipping},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.skipped_phases[Player.Draw] and  --FIXME: 此时机无data，需补充
      player:usedSkillTimes(self.name, Player.HistoryRound) < 2
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
joyex__duanliang:addRelatedSkill(joyex__duanliang_targetmod)
xuhuang:addSkill(joyex__duanliang)
xuhuang:addSkill(joyex__jiezi)
Fk:loadTranslationTable{
  ["joyex__xuhuang"] = "界徐晃",
  ["joyex__duanliang"] = "断粮",
  [":joyex__duanliang"] = "你可以将一张黑色基本牌或装备牌当【兵粮寸断】使用；你对手牌数不小于你的角色使用【兵粮寸断】无距离限制。",
  ["joyex__jiezi"] = "截辎",
  [":joyex__jiezi"] = "锁定技，每轮限两次，一名其他角色跳过摸牌阶段后，你摸两张牌。",
  ["#joyex__duanliang"] = "断粮：你可以将一张黑色基本牌或装备牌当【兵粮寸断】使用",
}

local caopi = General(extension, "joyex__caopi", "wei", 3)
local joyex__xingshang = fk.CreateTriggerSkill{
  name = "joyex__xingshang",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not target:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(target:getCardIds("he"))
    room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    if player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
local joyex__fangzhu = fk.CreateTriggerSkill{
  name = "joyex__fangzhu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#joyex__fangzhu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = player.room:getPlayerById(self.cost_data)
    to:drawCards(1, self.name)
    to:turnOver()
  end,
}
caopi:addSkill(joyex__xingshang)
caopi:addSkill(joyex__fangzhu)
caopi:addSkill("songwei")
Fk:loadTranslationTable{
  ["joyex__caopi"] = "界曹丕",
  ["joyex__xingshang"] = "行殇",
  [":joyex__xingshang"] = "当其他角色死亡时，你可以获得其所有牌并摸一张牌。",
  ["joyex__fangzhu"] = "放逐",
  [":joyex__fangzhu"] = "当你受到伤害后，你可以令一名其他角色翻面，然后其摸一张牌。",
  ["#joyex__fangzhu-choose"] = "放逐：你可以令一名其他角色翻面，然后其摸一张牌",
}

local wangji = General(extension, "joyex__wangji", "wei", 3)
local joyex__qizhi = fk.CreateTriggerSkill{
  name = "joyex__qizhi",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase ~= Player.NotActive and
      data.firstTarget and data.card.type ~= Card.TypeEquip
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isNude() and not table.contains(AimGroup:getAllTargets(data.tos), p.id) end), function(p) return p.id end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#joyex__qizhi-choose:::"..data.card:getTypeString(), self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@joyex__qizhi-turn", 1)
    local to = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, to, "he", self.name)
    local type = Fk:getCardById(id).type
    room:throwCard({id}, self.name, to, player)
    if type == data.card.type and not player.dead then
      player:drawCards(1, self.name)
    elseif type ~= data.card.type and not to.dead then
      to:drawCards(1, self.name)
    end
  end,
}
local joyex__jinqu = fk.CreateTriggerSkill{
  name = "joyex__jinqu",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    local n = player:getHandcardNum() - player:usedSkillTimes("joyex__qizhi", Player.HistoryTurn) - 1
    if n > 0 then
      player.room:askForDiscard(player, n, n, false, self.name, false)
    end
    return true
  end,
}
wangji:addSkill(joyex__qizhi)
wangji:addSkill(joyex__jinqu)
Fk:loadTranslationTable{
  ["joyex__wangji"] = "界王基",
  ["joyex__qizhi"] = "奇制",
  [":joyex__qizhi"] = "当你于回合内使用基本牌或锦囊牌指定目标后，你可以弃置不为此牌目标的一名角色一张牌。若弃置的牌与你使用的牌类型相同，"..
  "你摸一张牌；类型不同，其摸一张牌。",
  ["joyex__jinqu"] = "进趋",
  [":joyex__jinqu"] = "弃牌阶段开始前，你可以跳过此阶段并摸两张牌，然后将手牌弃至X张（X为你本回合发动〖奇制〗次数+1）。",
  ["@joyex__qizhi-turn"] = "奇制",
  ["#joyex__qizhi-choose"] = "奇制：弃置一名角色一张牌，若为%arg，你摸一张牌，否则其摸一张牌",
}


local simayi = General(extension, "joyex__simayi", "wei", 3)
local joyex__guicai = fk.CreateTriggerSkill{
  name = "joyex__guicai",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForResponse(player, self.name, ".|.|.|hand,equip|.|", "#joyex__guicai-ask::" .. target.id .. ":" .. data.reason, true)
    if card ~= nil then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(self.cost_data, player, data, self.name)
    if player.dead then return end
    if self.cost_data.suit == Card.Club then
      player:drawCards(2, self.name)
    elseif self.cost_data.suit == Card.Heart and player:isWounded() then
      player.room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
      })
    end
  end,
}
local joyex__fankui = fk.CreateTriggerSkill{
  name = "joyex__fankui",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost or player.dead then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.suit == Card.Heart then
      local targets = table.map(table.filter(room.alive_players, function(p) return not p:isNude() end), Util.IdMapper)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#joyex__fankui-choose", self.name, false)
      local to = room:getPlayerById(tos[1])
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:obtainCard(player, card, false, fk.ReasonPrey)
    else
      local from = data.from
      if from and not from.dead and not from:isNude() then
        room:doIndicate(player.id, {from.id})
        local card = room:askForCardChosen(player, from, "he", self.name)
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
    end
  end,
}
simayi:addSkill(joyex__guicai)
simayi:addSkill(joyex__fankui)
Fk:loadTranslationTable{
  ["joyex__simayi"] = "界司马懿",
  ["joyex__guicai"] = "鬼才",
  [":joyex__guicai"] = "任何判定牌生效前，你可以打出一张牌代替之，若此牌为红桃，你回复1点体力，若此牌为梅花，你摸两张牌。",
  ["joyex__fankui"] = "反馈",
  [":joyex__fankui"] = "当你受到1点伤害后，你可以进行判定：红桃，你获得场上任意角色的一张牌；其他花色，你获得伤害来源一张牌。",

  ["#joyex__guicai-ask"] = "鬼才：你可打出一张牌代替 %dest 的 %arg 判定;若为红桃，你回复1点体力，若为梅花，你摸两张牌。",
  ["#joyex__fankui-choose"] = "反馈：获得一名角色的一张牌。",

  ["$joyex__guicai1"] = "天命难违？哈哈哈哈哈……",
  ["$joyex__guicai2"] = "才通天地，逆天改命！",
  ["$joyex__fankui1"] = "哼，自作孽不可活！",
  ["$joyex__fankui2"] = "哼，正中下怀！",
  ["~joyex__simayi"] = "我的气数，就到这里了么？",
}

return extension
