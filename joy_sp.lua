local extension = Package("joy_sp")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_sp"] = "欢乐-SP",
  ["joysp"] = "欢乐SP",
}

local U = require "packages/utility/utility"


local ganfuren = General(extension, "joy__ganfuren", "shu", 3, 3, General.Female)
local joy__shushen = fk.CreateTriggerSkill{
  name = "joy__shushen",
  anim_type = "support",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__shushen-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if not player.dead then
      player:drawCards(1, self.name)
    end
    if not target.dead then
      target:drawCards(1, self.name)
    end
    return true
  end,
}
local joy__shushen_trigger = fk.CreateTriggerSkill{
  name = "#joy__shushen_trigger",
  main_skill = joy__shushen,
  mute = true,
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(joy__shushen)
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
      Util.IdMapper), 1, 1, "#joy__shushen-choose", self.name, true)
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
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__huangsi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    local ids = table.filter(player:getCardIds("h"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
    if #ids == 0 then return end
    room:throwCard(ids, self.name, player, player)
    if player.dead then return end
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
    "#joy__huangsi-choose:::"..(#ids + 2), self.name, true)
    if #to > 0 then
      room:getPlayerById(to[1]):drawCards(#ids + 2, self.name)
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
  [":joy__huangsi"] = "限定技，当你处于濒死状态时，你可以回复体力至1点并弃置所有手牌，然后你可以令一名角色摸X+2张牌（X为你弃置的牌数）。",
  ["#joy__shushen-invoke"] = "淑慎：你可以失去1点体力防止 %dest 受到的伤害，然后你与其各摸一张牌",
  ["#joy__shushen-choose"] = "淑慎：你可以令一名其他角色摸一张牌",
  ["#joy__huangsi-invoke"] = "皇思：你可以回复体力至1，弃置所有手牌",
  ["#joy__huangsi-choose"] = "皇思：你可以令一名角色摸 %arg 张牌",
}

local joy__caoang = General(extension, "joy__caoang", "wei", 4)
local joy__kangkai = fk.CreateTriggerSkill{
  name = "joy__kangkai",
  anim_type = "support",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "slash" and
    (player == target or player:distanceTo(target) == 1)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__kangkai-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if player == target or player:isNude() or target.dead or player:getMark("joy__kangkai-turn") == 2 then return end
    local cards = room:askForCard(player, 1, 1, true, self.name, true, ".", "#joy__kangkai-give::"..target.id)
    if #cards > 0 then
      room:addPlayerMark(player, "joy__kangkai-turn")
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true, player.id)
      local card = Fk:getCardById(cards[1])
      if card.type == Card.TypeEquip and not target.dead and not target:isProhibited(target, card) and not target:prohibitUse(card) and
        table.contains(target:getCardIds("h"), card.id) and
        room:askForSkillInvoke(target, self.name, data, "#kangkai-use:::"..card:toLogString()) then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = card,
        })
      end
    end
  end,
}
joy__caoang:addSkill(joy__kangkai)
Fk:loadTranslationTable{
  ["joy__caoang"] = "曹昂",
  ["#joy__caoang"] = "取义成仁",
  ["joy__kangkai"] = "慷忾",
  [":joy__kangkai"] = "当一名角色成为【杀】的目标后，若你与其的距离不大于1，你可以摸一张牌，然后可以交给该角色一张牌再令其展示之（每回合限两次），若此牌为装备牌，其可以使用之。",
  ["#joy__kangkai-invoke"] = "慷忾：你可以摸一张牌",
  ["#joy__kangkai-give"] = "慷忾：可以选择一张牌交给 %dest",
}


local joy__zhugedan = General(extension, "joy__zhugedan", "wei", 4)
local joy__gongao = fk.CreateTriggerSkill{
  name = "joy__gongao",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if not player.dead and player:isWounded() then
      room:recover { num = 1, skillName = self.name, who = player, recoverBy = player}
    end
  end,
}
local joy__juyi = fk.CreateTriggerSkill{
  name = "joy__juyi",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.maxHp > #player.room.alive_players and player:hasSkill(self) and
     player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    local n = player.maxHp - #player.player_cards[Player.Hand]
    if n > 0 then
      player:drawCards(n, self.name)
    end
    player.room:handleAddLoseSkills(player, "joy__benghuai|ty_ex__weizhong")
  end,
}
joy__zhugedan:addSkill(joy__gongao)
joy__zhugedan:addSkill(joy__juyi)
joy__zhugedan:addRelatedSkill("ty_ex__weizhong")
joy__zhugedan:addRelatedSkill("joy__benghuai")
Fk:loadTranslationTable{
  ["joy__zhugedan"] = "诸葛诞",
  ["#joy__zhugedan"] = "薤露蒿里",
  ["joy__gongao"] = "功獒",
  [":joy__gongao"] = "锁定技，每当一名其他角色进入濒死状态时，你增加1点体力上限，然后回复1点体力。",
  ["joy__juyi"] = "举义",
  [":joy__juyi"] = "限定技，准备阶段，若你体力上限大于全场角色数，你可以将手牌摸至体力上限，然后获得技能〖崩坏〗和〖威重〗。",
}

local joy__guanyinping = General(extension, "joy__guanyinping", "shu", 3, 3, General.Female)
local joy__huxiao = fk.CreateTriggerSkill{
  name = "joy__huxiao",
  anim_type = "offensive",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and data.damageType == fk.FireDamage and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    if data.to.dead then return end
    local mark = U.getMark(data.to, "@@joy__huxiao-turn")
    table.insertIfNeed(mark, player.id)
    player.room:setPlayerMark(data.to, "@@joy__huxiao-turn", mark)
  end,
}
local joy__huxiao_targetmod = fk.CreateTargetModSkill{
  name = "#joy__huxiao_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return table.contains(to:getTableMark("@@joy__huxiao-turn"), player.id)
  end,
}
joy__huxiao:addRelatedSkill(joy__huxiao_targetmod)
local joy__wuji = fk.CreateTriggerSkill{
  name = "joy__wuji",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local n = 0
    player.room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data[1]
      n = n + damage.damage
      if n > 2 then return true end
    end)
    return n > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() and not player.dead then
      room:recover({ who = player, num = 1, recoverBy = player, skillName = self.name })
    end
    if player.dead then return end
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id).name == "blade" then
        if room:getCardArea(id) == Card.DrawPile or room:getCardArea(id) == Card.DiscardPile or room:getCardArea(id) == Card.PlayerEquip then
          room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, self.name)
          break
        end
      end
    end
  end,
}
joy__guanyinping:addSkill("ol__xuehen")
joy__guanyinping:addSkill(joy__huxiao)
joy__guanyinping:addSkill(joy__wuji)
Fk:loadTranslationTable{
  ["joy__guanyinping"] = "关银屏",
  ["#joy__guanyinping"] = "武姬",

  ["joy__huxiao"] = "虎啸",
  [":joy__huxiao"] = "锁定技，当你对一名角色造成火焰伤害后，本回合你对其使用牌无次数限制。",
  ["@@joy__huxiao-turn"] = "虎啸",
  ["joy__wuji"] = "武继",
  [":joy__wuji"] = "觉醒技，结束阶段，若你本回合造成过至少3点伤害，你加1点体力上限并回复1点体力，，然后从牌堆、弃牌堆或场上获得【青龙偃月刀】。",
}

local joyex__sunqian = General(extension, "joyex__sunqian", "shu", 3)
local joyex__qianya = fk.CreateTriggerSkill{
  name = "joyex__qianya",
  anim_type = "support",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.type == Card.TypeTrick and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local tos, cards = player.room:askForChooseCardsAndPlayers(player, 1, player:getHandcardNum(), table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, ".", "#joyex__qianya-invoke", self.name, true)
    if #tos > 0 and #cards > 0 then
      self.cost_data = {tos[1], cards}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(self.cost_data[2], Card.PlayerHand, player.room:getPlayerById(self.cost_data[1]), fk.ReasonGive, self.name, "", true, player.id)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|^Equip")
    if #cards > 0 and not player.dead then
      local get = cards[1]
      local card = Fk:getCardById(get)
      room:obtainCard(player, get, false, fk.ReasonDraw)
    end
  end,
}

joyex__sunqian:addSkill(joyex__qianya)
joyex__sunqian:addSkill("shuimeng")
Fk:loadTranslationTable{
  ["joyex__sunqian"] = "界孙乾",
  ["#joyex__sunqian"] = "折冲樽俎",

  ["joyex__qianya"] = "谦雅",
  [":joyex__qianya"] = "当你成为锦囊牌的目标后，你可以将任意张手牌交给一名其他角色,并从牌堆获得一张非装备牌。",
  ["#joyex__qianya-invoke"] = "谦雅：你可以将任意张手牌交给一名其他角色并获得一张非装备牌",

}

local xizhicai = General(extension, "joy__xizhicai", "wei", 3)
local updataXianfu = function (room, player, target)
  local mark = player:getTableMark("xianfu")
  table.insertIfNeed(mark[2], target.id)
  room:setPlayerMark(player, "xianfu", mark)
  local names = table.map(mark[2], function(pid) return Fk:translate(room:getPlayerById(pid).general) end)
  room:setPlayerMark(player, "@xianfu", table.concat(names, ","))
end
local chouce = fk.CreateTriggerSkill{
  name = "joy__chouce",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost or not player:hasSkill(self) then break end
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
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      local targets = table.map(room.alive_players, Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#joy__chouce-draw", self.name, false)
      local to = room:getPlayerById(tos[1])
      local num = 1
      local mark = player:getTableMark("xianfu")
      if #mark > 0 and table.contains(mark[1], to.id) then
        num = 2
        updataXianfu (room, player, to)
      end
      to:drawCards(num, self.name)
    elseif judge.card.color == Card.Black then
      local targets = table.map(table.filter(room.alive_players, function(p) return not p:isAllNude() end), Util.IdMapper)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#joy__chouce-discard", self.name, false)
      local to = room:getPlayerById(tos[1])
      local card = room:askForCardChosen(player, to, "hej", self.name)
      room:obtainCard(player,card,false, fk.ReasonPrey)
    end
  end,
}
xizhicai:addSkill("xianfu")
xizhicai:addSkill("tiandu")
xizhicai:addSkill(chouce)
Fk:loadTranslationTable{
  ["joy__xizhicai"] = "戏志才",
  ["#joy__xizhicai"] = "负俗的天才",

  ["joy__chouce"] = "筹策",
  [":joy__chouce"] = "当你受到1点伤害后，你可以进行判定，若结果为：黑色，你获得一名角色区域里的一张牌；红色，你令一名角色摸一张牌（先辅的角色摸两张）。",

  ["#joy__chouce-draw"] = "筹策: 令一名角色摸一张牌（若为先辅角色则摸两张）",
  ["#joy__chouce-discard"] = "筹策: 获得一名角色区域里的一张牌",

}

local joy__sunhao = General(extension, "joy__sunhao", "wu", 5)
local joy__canshi = fk.CreateTriggerSkill{
  name = "joy__canshi",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.find(player.room.alive_players, function (p)
      return p:isWounded() or (player:hasSkill("joy__guiming") and p.kingdom == "wu" )
    end)
  end,
  on_cost = function (self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room.alive_players) do
      if p:isWounded() or (player:hasSkill("joy__guiming") and p.kingdom == "wu" ) then
        n = n + 1
      end
    end
    if player.room:askForSkillInvoke(player, self.name, nil, "#joy__canshi-invoke:::"..n) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + self.cost_data
  end,
}
local joy__canshi_delay = fk.CreateTriggerSkill{
  name = "#joy__canshi_delay",
  anim_type = "negative",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and
      player:usedSkillTimes(joy__canshi.name) > 0 and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, true, self.name, false)
  end,
}
local joy__chouhai = fk.CreateTriggerSkill{
  name = "joy__chouhai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events ={fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isKongcheng() and #player:getCardIds("e") == 0 and data.card and data.card.trueName == "slash"
    
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local guiming = fk.CreateTriggerSkill{
  name = "joy__guiming$",
  frequency = Skill.Compulsory,
}
joy__canshi:addRelatedSkill(joy__canshi_delay)
joy__sunhao:addSkill(joy__canshi)
joy__sunhao:addSkill(joy__chouhai)
joy__sunhao:addSkill(guiming)
Fk:loadTranslationTable{
  ["joy__sunhao"] = "孙皓",
  ["#joy__sunhao"] = "时日曷丧",

  ["joy__canshi"] = "残蚀",
  [":joy__canshi"] = "摸牌阶段，你可以多摸X张牌（X为已受伤的角色数），若如此做，当你于此回合内使用【杀】时，你弃置一张牌。",
  ["#joy__canshi_delay"] = "残蚀",
  ["joy__chouhai"] = "仇海",
  [":joy__chouhai"] = "锁定技，当你受到【杀】造成的伤害时，若你没有手牌和装备，此伤害+1。",
  ["#joy__canshi-invoke"] = "残蚀：你可以多摸 %arg 张牌",

  ["joy__guiming"] = "归命",
  [":joy__guiming"] = "主公技，锁定技，吴势力角色于你的回合内视为已受伤的角色。",

}

local sunshangxiang = General(extension, "joysp__sunshangxiang", "shu", 3, 3, General.Female)
local joy__liangzhu = fk.CreateTriggerSkill{
  name = "joy__liangzhu",
  anim_type = "support",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"Cancel", "draw1", "joy__liangzhu_draw2::"..target.id, "joy__liangzhu_prey::"..target.id}
    local choices = table.simpleClone(all_choices)
    if target:getEquipment(Card.SubtypeWeapon) == nil then
      table.removeOne(choices, choices[4])
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#joy__liangzhu-choice::"..target.id, false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "draw1" then
      player:drawCards(1, self.name)
    elseif self.cost_data[15] == "d" then
      room:doIndicate(player.id, {target.id})
      target:drawCards(2, self.name)
    else
      room:doIndicate(player.id, {target.id})
      room:obtainCard(player, target:getEquipment(Card.SubtypeWeapon), true, fk.ReasonPrey)
    end
  end,
}
local joy__fanxiang = fk.CreateTriggerSkill{
  name = "joy__fanxiang",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("joy__liangzhu", Player.HistoryGame) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "xiaoji|joy__wujian", nil)
  end,
}
local joy__wujian = fk.CreateViewAsSkill{
  name = "joy__wujian",
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#joy__wujian",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Equip and
      Self:getMark("joy__wujian_"..Fk:getCardById(to_select):getSubtypeString().."-phase") == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function (self, player, use)
    player.room:setPlayerMark(player, "joy__wujian_"..Fk:getCardById(use.card.subcards[1]):getSubtypeString().."-phase", 1)
    use.extraUse = true
  end,
  enabled_at_response = function(self, player, response)
    return not response and player.phase == Player.Play
  end,
}
local joy__wujian_targetmod = fk.CreateTargetModSkill{
  name = "#joy__wujian_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "joy__wujian")
  end,
}
joy__wujian:addRelatedSkill(joy__wujian_targetmod)
sunshangxiang:addSkill(joy__liangzhu)
sunshangxiang:addSkill(joy__fanxiang)
sunshangxiang:addRelatedSkill("xiaoji")
sunshangxiang:addRelatedSkill(joy__wujian)
Fk:loadTranslationTable{
  ["joysp__sunshangxiang"] = "孙尚香",
  ["joy__liangzhu"] = "良助",
  [":joy__liangzhu"] = "当一名角色于其出牌阶段内回复体力后，你可以选择一项：1.摸一张牌；2.令其摸两张牌；3.获得其装备区内的武器牌。",
  ["joy__fanxiang"] = "返乡",
  [":joy__fanxiang"] = "觉醒技，准备阶段，若你发动过〖良助〗，你加1点体力上限并回复1点体力，然后获得〖枭姬〗和〖舞剑〗。",
  ["joy__wujian"] = "舞剑",
  [":joy__wujian"] = "出牌阶段，你可以将装备区内的装备当不计次数的【杀】使用，每种类别每阶段限一次。",
  ["#joy__liangzhu-choice"] = "良助：你可以对 %dest 发动“良助”，选择执行一项",
  ["joy__liangzhu_draw2"] = "令 %dest 摸两张牌",
  ["joy__liangzhu_prey"] = "获得 %dest 的武器",
  ["#joy__wujian"] = "舞剑：你可以将装备区内的装备当不计次数的【杀】使用",
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
    if player:hasSkill(self) then
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
    if player:hasSkill(self) then
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
    if target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" then
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
        if not player.dead and player:hasSkill(self) and not p.dead and not p:isKongcheng() then
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
    local n = target:isMale() and 2 or 1
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
    return target == player and player:hasSkill(self) and data.name == "joy__xingwu"
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
    if target == player and player:hasSkill(self) and player.phase == Player.NotActive and
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
      return not p.faceup end), Util.IdMapper),
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
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() end), Util.IdMapper)
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



local pangtong = General(extension, "joysp__pangtong", "wu", 3)
local guolun = fk.CreateActiveSkill{
  name = "joy__guolun",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id1 = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(id1)
    if not target.dead and not player:isNude() then
      local n1 = Fk:getCardById(id1).number
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".", "#joy__guolun-card:::"..tostring(n1))
      if #card > 0 then
        local id2 = card[1]
        player:showCards(id2)
        local n2 = Fk:getCardById(id2).number
        if player.dead then return end
        local move1 = {
          from = effect.from,
          ids = {id2},
          to = effect.tos[1],
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = effect.from,
          skillName = self.name,
        }
        local move2 = {
          from = effect.tos[1],
          ids ={id1},
          to = effect.from,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = effect.from,
          skillName = self.name,
        }
        room:moveCards(move1, move2)
        if n2 > n1 and not target.dead then
          target:drawCards(1, self.name)
          room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          })
        elseif n1 > n2 and not player.dead then
          player:drawCards(2, self.name)
        end
      end
    end
  end,
}
local songsang = fk.CreateTriggerSkill{
  name = "joy__songsang",
  anim_type = "support",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) 
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name,
    })
  end,
}
pangtong:addSkill(guolun)
pangtong:addSkill(songsang)
pangtong:addSkill("zhanji")
Fk:loadTranslationTable{
  ["joysp__pangtong"] = "庞统",
  ["#joysp__pangtong"] = "南州士冠",

  ["joy__guolun"] = "过论",
  [":joy__guolun"] = "出牌阶段限一次，你可以展示一名其他角色的一张手牌，然后你可以展示一张手牌，交换这两张牌"..
    "若其选择的点数小，其摸一张牌，你回复一点体力；"..
    "若你选择的点数小，你摸两张牌",
  ["joy__songsang"] = "送丧",
  [":joy__songsang"] = "当其他角色死亡时，你可加1点体力上限并回复1点体力。",

  ["#joy__guolun-card"] = "过论：你可以选择一张牌并交换双方的牌（对方点数为%arg）",

}

local caiwenji = General(extension, "joysp__caiwenji", "wei", 3, 3, General.Female)
local chenqing = fk.CreateTriggerSkill{
  name = "joy__chenqing",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
    not table.every(player.room.alive_players, function (p)
      return p == player or p == target
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if p ~= target then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#joy__chenqing-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    to:drawCards(5, self.name)
    local cards = room:askForDiscard(to, 4, 4, true, self.name, false, ".", "#joy__chenqing-discard", true)
    local suits = {}
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).suit ~= Card.NoSuit then
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
    end
    room:throwCard(cards, self.name, to, to)
    if #suits == 4 and not to.dead and not target.dead then
      room:useVirtualCard("peach", nil, to, target, self.name)
    end
  end,
}

caiwenji:addSkill(chenqing)
caiwenji:addSkill("mozhi")
Fk:loadTranslationTable{
  ["joysp__caiwenji"] = "蔡文姬",
  ["#joysp__caiwenji"] = "金璧之才",

  ["joy__chenqing"] = "陈情",
  [":joy__chenqing"] = "每回合限一次，当一名角色进入濒死状态时，你可以令另一名角色摸五张牌，然后弃置四张牌，"..
  "若其以此法弃置的四张牌的花色各不相同，则其视为对濒死状态的角色使用一张【桃】。",

  ["#joy__chenqing-choose"] = "陈情：令一名角色摸五张牌然后弃四张牌，若花色各不相同视为对濒死角色使用【桃】",
  ["#joy__chenqing-discard"] = "陈情：需弃置四张牌，若花色各不相同则视为对濒死角色使用【桃】",
}

local joysp__zhangfei = General(extension, "joysp__zhangfei", "shu", 4)
local joysp__paoxiao = fk.CreateTargetModSkill{
  name = "joysp__paoxiao",
  frequency = Skill.Compulsory,
  bypass_times = function(self, player, skill, scope)
    return player:hasSkill(self) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase
  end,
  bypass_distances = function(self, player, skill, scope)
    return player:hasSkill(self) and skill.trueName == "slash_skill"
  end,
}
local joysp__paoxiao_trigger = fk.CreateTriggerSkill{
  name = "#joysp__paoxiao_trigger",
  events = {fk.TargetSpecified},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player and data.card.trueName == "slash" then
      local times = #player.room.logic:getEventsOfScope(GameEvent.UseCard, 3, function(e)
        local use = e.data[1]
        return use.from == player.id and use.card.trueName == "slash"
      end, Player.HistoryTurn)
      return (times == 2 and data.firstTarget) or times > 2
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local times = #room.logic:getEventsOfScope(GameEvent.UseCard, 3, function(e)
      local use = e.data[1]
      return use.from == player.id and use.card.trueName == "slash"
    end, Player.HistoryTurn)
    if data.firstTarget then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
    if times > 2 then
      data.disresponsive = true
      room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
      data.extra_data = data.extra_data or {}
      data.extra_data.joysp__paoxiao = data.extra_data.joysp__paoxiao or {}
      data.extra_data.joysp__paoxiao[tostring(data.to)] = (data.extra_data.joysp__paoxiao[tostring(data.to)] or 0) + 1
    end
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.joysp__paoxiao
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.joysp__paoxiao) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.extra_data.joysp__paoxiao = nil
  end,
}
joysp__paoxiao:addRelatedSkill(joysp__paoxiao_trigger)
local joy__xuhe = fk.CreateTriggerSkill{
  name = "joy__xuhe",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardEffectCancelledOut, fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardEffectCancelledOut then
      return target == player and player:hasSkill(self) and data.card.trueName == "slash"
    else
      return target == player and player:hasSkill(self) and data.card.name == "jink"
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

}
joysp__zhangfei:addSkill(joysp__paoxiao)
joysp__zhangfei:addSkill(joy__xuhe)
Fk:loadTranslationTable{
  ["joysp__zhangfei"] = "张飞",
  
  ["joysp__paoxiao"] = "咆哮",
  ["#joysp__paoxiao_trigger"] = "咆哮",
  [":joysp__paoxiao"] = "锁定技，你使用【杀】无次数距离限制，每回合第二张【杀】起伤害+1；第三张【杀】起无视防具且不可响应。",
  ["joy__xuhe"] = "虚吓",
  [":joy__xuhe"] = "锁定技，你的【杀】被【闪】抵消后，摸一张牌；你使用或打出【闪】后，摸一张牌。",
}

local pangde = General(extension, "joysp__pangde", "wei", 4)
local juesi = fk.CreateActiveSkill{
  name = "joysp__juesi",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash" and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and not target:isNude() and Self:inMyAttackRange(target)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local card = room:askForDiscard(target, 1, 1, true, self.name, false, ".", "#joy__juesi-discard:"..player.id)
    if #card > 0 then
      card = Fk:getCardById(card[1])
      if card.trueName ~= "slash" and  player.hp  <= target.hp  and not player.dead and not target.dead then
        if player.room:askForSkillInvoke(player,self.name,".","#joy__juesi-drawCards") then
          player:drawCards(2,self.name)
        end
      elseif card.trueName == "slash"  and not player.dead and not target.dead then
        room:useVirtualCard("duel", nil, player, target, self.name)
      end
    end
  end,
}
pangde:addSkill("joy__yuma")
pangde:addSkill(juesi)
Fk:loadTranslationTable{
  ["joysp__pangde"] = "庞德",
  ["#joysp__pangde"] = "抬榇之悟",

  ["joysp__juesi"] = "决死",
  [":joysp__juesi"] = "出牌阶段，你可以弃置一张【杀】并选择攻击范围内的一名其他角色，然后令该角色弃置一张牌。"..
  "若该角色弃置的牌不为【杀】且你的体力值小于等于该角色，则你可以摸两张牌；若弃置的是杀，你视为对其使用一张【决斗】。",

  ["#joy__juesi-discard"] = "决死：你需弃置一张牌，若不为【杀】且 %src 体力值小于等于你，其可摸两张牌，若为【杀】，视为其对你使用【决斗】",
  ["#joy__juesi-drawCards"] = "决死：是否摸两张牌",

}

local diaochan = General(extension, "joysp__diaochan", "qun", 3, 3, General.Female)
local lihun = fk.CreateActiveSkill{
  name = "joy__lihun",
  mute = true,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 
  end,
  target_filter = function(self, to_select, selected, cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and
    not target:isKongcheng() and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:broadcastSkillInvoke(self.name, 1)
    room:notifySkillInvoked(player, self.name, "control")
    local mark = player:getMark("joy__lihun-phase")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, target.id)
    room:setPlayerMark(player, "joy__lihun-phase", mark)
    player:turnOver()
    if player.dead or target.dead or target:isKongcheng() then return end
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(target:getCardIds("h"))
    room:moveCardTo(dummy, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
  end,
}
local lihun_record = fk.CreateTriggerSkill{
  name = "#joy__lihun_record",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("joy__lihun-phase") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("joy__lihun", 2)
    room:notifySkillInvoked(player, "joy__lihun", "control")
    local mark = player:getMark("joy__lihun-phase")
    for _, id in ipairs(mark) do
      if player.dead or player:isNude() then return end
      local to = room:getPlayerById(id)
      if not to.dead then
        local cards = player:getCardIds("he")
        local n = to.hp
        if n < #cards then
          cards = room:askForCard(player, n, n, true, "joy__lihun", false, ".", "#lihun-give::"..to.id..":"..n)
        end
        room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, "joy__lihun", nil, false, player.id)
      end
    end
  end,
}
local biyue = fk.CreateTriggerSkill{
  name = "joysp__biyue",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) 
  end,
  on_use = function(self, event, target, player, data)
    local n = 1
    if not player.faceup then
      n = 3
    end
    player:drawCards(n, self.name)
  end,
}
lihun:addRelatedSkill(lihun_record)
diaochan:addSkill(lihun)
diaochan:addSkill(biyue)
Fk:loadTranslationTable{
  ["joysp__diaochan"] = "貂蝉",
  ["#joysp__diaochan"] = "暗黑的傀儡师",

  ["joy__lihun"] = "离魂",
  [":joy__lihun"] = "出牌阶段限一次，你可翻面，并获得一名其他角色所有手牌。"..
  "出牌阶段结束时，你交给该角色X张牌（X为其体力值）。",
  ["joysp__biyue"] = "闭月",
  [":joysp__biyue"] = "回合结束阶段开始时，你可以摸一张牌，如你处于翻面状态，则摸三张牌。",
}

local yangxiu = General(extension, "joy__yangxiu", "wei", 3)
local jilei = fk.CreateTriggerSkill{
  name = "joy__jilei",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil,
    (data.from and not data.from.dead) and ("#joy__jilei-invoke::"..data.from.id) or "#joy__jilei-draw")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"basic", "trick", "equip"}, self.name)
    local ids = room:getCardsFromPileByRule(".|.|.|.|.|"..choice)
    if #ids > 0 then
      room:moveCardTo(ids, Player.Hand, player, fk.ReasonPrey, self.name)
    end
    if data.from and not data.from.dead then
      local mark = U.getMark(data.from, "@joy__jilei")
      table.insertIfNeed(mark, choice .. "_char")
      room:setPlayerMark(data.from, "@joy__jilei", mark)
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@joy__jilei") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@joy__jilei", 0)
  end,
}
local function jileiCheck (player, card)
  local mark = player:getMark("@joy__jilei")
  if type(mark) == "table" and table.contains(mark, card:getTypeString() .. "_char") then
    local subcards = card:isVirtual() and card.subcards or {card.id}
    return #subcards > 0 and table.every(subcards, function(id)
      return table.contains(player.player_cards[Player.Hand], id)
    end)
  end
  return false
end
local jilei_prohibit = fk.CreateProhibitSkill{
  name = "#joy__jilei_prohibit",
  prohibit_use = function(_, player, card)
    return jileiCheck(player, card)
  end,
  prohibit_response = function(_, player, card)
    return jileiCheck(player, card)
  end,
  prohibit_discard = function(_, player, card)
    return jileiCheck(player, card)
  end,
}
jilei:addRelatedSkill(jilei_prohibit)
yangxiu:addSkill("ty__danlao")
yangxiu:addSkill(jilei)
Fk:loadTranslationTable{
  ["joy__yangxiu"] = "杨修",
  ["#joy__yangxiu"] = "恃才放旷",

  ["joy__jilei"] = "鸡肋",
  [":joy__jilei"] = "当你受到伤害后，你可以声明一种牌的类别，然后获得一张该类别的牌，并令伤害来源不能使用、打出或弃置你声明的此类别的手牌直到其下回合开始。",
  ["#joy__jilei-invoke"] = "鸡肋：你可以获得一张指定类别的牌，令 %dest 不能使用、打出、弃置该类别牌直到其下回合开始",
  ["#joy__jilei-draw"] = "鸡肋：你可以获得一张指定类别的牌",
  ["@joy__jilei"] = "鸡肋",
}

local liuxie = General(extension, "joy__liuxie", "qun", 3)
local tianming = fk.CreateTriggerSkill{
  name = "joy__tianming",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    local ids = table.filter(player:getCardIds("he"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
    if #ids < 3 then
      if player.room:askForSkillInvoke(player, self.name, data, "#tianming-cost") then
        self.cost_data = ids
        return true
      end
    else
      local cards = player.room:askForDiscard(player, 2, 2, true, self.name, true, ".", "#tianming-cost", true)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if not player.dead then
      player:drawCards(2, self.name)
    end
    if player.dead then return end
    local tos = room:askForChoosePlayers(player,table.map(room.alive_players, Util.IdMapper),1,1,"#joy__tianming-choose",self.name,true)
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      room:askForDiscard(to, 2, 2, true, self.name, false)
      if not to.dead then
        to:drawCards(2, self.name)
      end
    end
  end,
}
local mizhao = fk.CreateActiveSkill{
  name = "joy__mizhao",
  anim_type = "control",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return table.contains(Self.player_cards[Player.Hand], to_select)
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and to_select ~= Self.id and #cards > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local cards = effect.cards
    room:moveCardTo(effect.cards, Player.Hand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead or to.dead then return end
    local targets = table.filter(room.alive_players, function(p)
      return to:canPindian(p)
    end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#mizhao-choose::"..to.id, self.name, false)
    local victim = room:getPlayerById(tos[1])
    local pindian = to:pindian({victim}, self.name)
    local winner = pindian.results[victim.id].winner
    if winner then
      local loser = (winner == to) and victim or to
      if loser.dead then return end
      room:useVirtualCard("slash", nil, winner, {loser}, self.name)
    end
  end
}
liuxie:addSkill(tianming)
liuxie:addSkill(mizhao)
Fk:loadTranslationTable{
  ["joy__liuxie"] = "刘协",
  ["#joy__liuxie"] = "受困天子",

  ["joy__tianming"] = "天命",
  [":joy__tianming"] = "当你成为【杀】的目标后，你可以弃置两张牌（不足则全弃，无牌则不弃），然后摸两张牌；然后你可以令一名角色也如此做，",
  ["joy__mizhao"] = "密诏",
  [":joy__mizhao"] = "出牌阶段限一次，你可以将至少一张手牌交给一名其他角色。若如此做，你令该角色与你指定的另一名有手牌的角色拼点，"..
  "视为拼点赢的角色对没赢的角色使用一张【杀】。",
  ["#joy__tianming-choose"] = "天命:可以令一名角色弃置两张牌，然后摸两张牌",
}


return extension
