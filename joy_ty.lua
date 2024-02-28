local extension = Package("joy_ty")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_ty"] = "欢乐-十周年改",
}

local U = require "packages/utility/utility"

-- 在十周年武将基础上修改的武将


local zhoufang = General(extension, "joy__zhoufang", "wu", 3)
local joy__youdi = fk.CreateTriggerSkill{
  name = "joy__youdi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#joy__youdi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(to, player, "h", self.name)
    room:throwCard({card}, self.name, player, to)
    if player.dead or to.dead then return end
    if Fk:getCardById(card).trueName ~= "slash" and not to:isNude() then
      local card2 = room:askForCardChosen(player, to, "he", self.name)
      room:obtainCard(player, card2, false, fk.ReasonPrey)
      if player.dead then return end
      player:drawCards(1, self.name)
    end
    if Fk:getCardById(card).color ~= Card.Black and player.maxHp < 5 and not player.dead then
      room:changeMaxHp(player, 1)
    end
  end,
}
zhoufang:addSkill("duanfa")
zhoufang:addSkill(joy__youdi)
Fk:loadTranslationTable{
  ["joy__zhoufang"] = "周鲂",
  ["joy__youdi"] = "诱敌",
  [":joy__youdi"] = "结束阶段，你可以令一名其他角色弃置你一张手牌，若弃置的牌不是【杀】，则你获得其一张牌并摸一张牌；若弃置的牌不是黑色，且你的体力上限小于5，则你增加1点体力上限。",
  ["#joy__youdi-choose"] = "诱敌：令一名角色弃置你手牌，若不是【杀】，你获得其一张牌并摸一张牌；若不是黑色，你加1点体力上限",
}

local tangji = General(extension, "joy__tangji", "qun", 3, 3, General.Female)
local joy__kangge = fk.CreateTriggerSkill{
  name = "joy__kangge",
  events = {fk.TurnStart, fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.TurnStart then
        return target == player
      else
        if player:getMark(self.name) ~= 0 and player:getMark("joy__kangge-turn") < 3 then
          for _, move in ipairs(data) do
            if move.to and move.toArea == Card.PlayerHand and player.room:getPlayerById(move.to):getMark("@@joy__kangge") > 0 and
              player.room:getPlayerById(move.to).phase == Player.NotActive then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.TurnStart then
      room:notifySkillInvoked(player, self.name, "special")
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if p:getMark("@@joy__kangge") > 0 then
          room:setPlayerMark(p, "@@joy__kangge", 0)
        end
      end
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#joy__kangge-choose", self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(targets)
      end
      room:setPlayerMark(room:getPlayerById(to), "@@joy__kangge", 1)
    elseif event == fk.AfterCardsMove then
      local n = 0
      for _, move in ipairs(data) do
        if move.to and room:getPlayerById(move.to):getMark("@@joy__kangge") > 0 and move.toArea == Card.PlayerHand then
          n = n + #move.moveInfo
        end
      end
      if n > 0 then
        room:notifySkillInvoked(player, self.name, "drawcard")
        local x = math.min(n, 3 - player:getMark("joy__kangge-turn"))
        room:addPlayerMark(player, "joy__kangge-turn", x)
        player:drawCards(x, self.name)
      end
    end
  end,
}
local joy__kangge_trigger = fk.CreateTriggerSkill{
  name = "#joy__kangge_trigger",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("joy__kangge") and target:getMark("@@joy__kangge") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "joy__kangge", nil, "#joy__kangge-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("joy__kangge")
    room:notifySkillInvoked(player, "joy__kangge", "support")
    room:doIndicate(player.id, {target.id})
    room:recover({
      who = target,
      num = 1 - target.hp,
      recoverBy = player,
      skillName = "joy__kangge"
    })
  end,
}
local joy__jielie = fk.CreateTriggerSkill{
  name = "joy__jielie",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__jielie-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = table.filter(room:getOtherPlayers(player), function(p) return p:getMark("@@joy__kangge") > 0 end)[1]
    local suit
    if to then
      local suits = {"spade", "heart", "club", "diamond"}
      local choices = table.map(suits, function(s) return Fk:translate("log_"..s) end)
      local choice = room:askForChoice(player, choices, self.name, "#joy__jielie-choice::"..to.id..":"..data.damage)
      suit = suits[table.indexOf(choices, choice)]
      room:doIndicate(player.id, {to.id})
    end
    room:loseHp(player, 1, self.name)
    if to and not to.dead then
      local cards = room:getCardsFromPileByRule(".|.|"..suit, data.damage, "discardPile")
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = to.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
    return true
  end,
}
joy__kangge:addRelatedSkill(joy__kangge_trigger)
tangji:addSkill(joy__kangge)
tangji:addSkill(joy__jielie)
Fk:loadTranslationTable{
  ["joy__tangji"] = "唐姬",
  ["joy__kangge"] = "抗歌",
  [":joy__kangge"] = "回合开始时，你选择一名其他角色：当该角色于其回合外获得手牌时，你摸等量的牌（每回合最多摸3张）；每轮限一次，当该角色"..
  "进入濒死状态时，你可以令其将体力回复至1点。场上仅能存在一名“抗歌”角色。",
  ["joy__jielie"] = "节烈",
  [":joy__jielie"] = "当你受到伤害时，你可以防止此伤害并选择一种花色，然后你失去1点体力，令“抗歌”角色从弃牌堆中随机获得X张此花色的牌（X为伤害值）。",
  ["#joy__kangge-choose"] = "抗歌：请选择“抗歌”角色",
  ["@@joy__kangge"] = "抗歌",
  ["#joy__kangge-invoke"] = "抗歌：你可以令 %dest 回复体力至1",
  ["#joy__jielie-invoke"] = "节烈：你可以防止你受到的伤害并失去1点体力",
  ["#joy__jielie-choice"] = "节烈：选择一种花色，令“抗歌”角色 %dest 从弃牌堆获得%arg张此花色牌",
}

local zhangxuan = General(extension, "joy__zhangxuan", "wu", 4, 4, General.Female)
local joy__tongli = fk.CreateTriggerSkill{
  name = "joy__tongli",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and data.firstTarget and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
      local suits = {}
      for _, id in ipairs(player:getCardIds("h")) do
        if Fk:getCardById(id).suit ~= Card.NoSuit then
          table.insertIfNeed(suits, Fk:getCardById(id).suit)
        end
      end
      return #suits == player:getMark("@joy__tongli-turn")
    end
  end,
  on_use = function(self, event, target, player, data)
    data.additionalEffect = (data.additionalEffect or 0) + player:getMark("@joy__tongli-turn")
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@joy__tongli-turn")
  end,
}
local joy__shezang = fk.CreateTriggerSkill{
  name = "joy__shezang",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (target == player or player == player.room.current) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {1, 2, 3, 4}
    local cards = {}
    local pile = table.simpleClone(room.draw_pile)
    while #pile > 0 and #cards < 4 do
      local id = table.remove(pile, math.random(#pile))
      if table.removeOne(suits, Fk:getCardById(id).suit) then
        table.insert(cards, id)
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
        moveVisible = true
      })
    end
  end,
}
zhangxuan:addSkill(joy__tongli)
zhangxuan:addSkill(joy__shezang)
Fk:loadTranslationTable{
  ["joy__zhangxuan"] = "张嫙",
  ["joy__tongli"] = "同礼",
  [":joy__tongli"] = "当你于出牌阶段内使用基本牌或普通锦囊牌指定目标后，若你手牌中的花色数等于你此阶段已使用牌的张数，你可令此牌效果额外执行X次（X为你手牌中的花色数）。",
  ["joy__shezang"] = "奢葬",
  [":joy__shezang"] = "每回合限一次，当你或你回合内有角色进入濒死状态时，你可以从牌堆获得不同花色的牌各一张。",
  ["@joy__tongli-turn"] = "同礼",
}



local joy__guansuo = General(extension, "joy__guansuo", "shu", 4)
local joy__zhengnan = fk.CreateTriggerSkill{
  name = "joy__zhengnan",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (player:getMark(self.name) == 0 or not table.contains(player:getMark(self.name), target.id))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(self.name)
    local n = 0
      if target == player and player:hasSkill(self) then
        n = 1
      end
    if mark == 0 then mark = {} end
    table.insert(mark, target.id)
    room:setPlayerMark(player, self.name, mark)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1+n,
        recoverBy = player,
        skillName = self.name
      })
    end
    local choices = {"joy__wusheng", "joyex__dangxian", "ty_ex__zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      player:drawCards(1+n, self.name)
      local choice = room:askForChoice(player, choices, self.name, "#joy__zhengnan-choice", true)
      room:handleAddLoseSkills(player, choice, nil)
    else
      player:drawCards(3+n, self.name)
    end
  end,
}
local joy__xiefang = fk.CreateDistanceSkill{
  name = "joy__xiefang",
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.gender == General.Female then
          n = n + 1
        end
      end
      local m = math.max(n,1)
      return -m
    end
    return 0
  end,
}
local joy__xiefang_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__xiefang_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.gender == General.Female then
          n = n + 1
        end
      end
      local m = math.max(n,1)
      return m
    end
    return 0
  end,
}


local joy__wusheng = fk.CreateTriggerSkill{
  name = "joy__wusheng",
  anim_type = "offensive",
  pattern = "slash",
  events = {fk.TurnStart, fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      return (event == fk.TurnStart) or (data.card.trueName == "slash" and data.card.color == Card.Red)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:notifySkillInvoked(player, "joy__wusheng", "drawcard")
      local ids = room:getCardsFromPileByRule("slash|.|heart,diamond", 1, "allPiles")
      if #ids > 0 then
        room:obtainCard(player, ids[1], false, fk.ReasonPrey)
      end
    else
      room:notifySkillInvoked(player, "joy__wusheng", "offensive")
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
joy__xiefang:addRelatedSkill(joy__xiefang_maxcards)
joy__guansuo:addSkill(joy__zhengnan)
joy__guansuo:addSkill(joy__xiefang)
joy__guansuo:addRelatedSkill(joy__wusheng)
joy__guansuo:addRelatedSkill("joyex__dangxian")
joy__guansuo:addRelatedSkill("ty_ex__zhiman")
Fk:loadTranslationTable{
  ["joy__guansuo"] = "关索",
  ["#joy__guansuo"] = "倜傥孑侠",

  ["joy__zhengnan"] = "征南",
  [":joy__zhengnan"] = "每名角色限一次，当一名角色进入濒死状态时，你可以回复1点体力，然后摸一张牌并选择获得下列技能中的一个："..
  "〖武圣〗，〖当先〗和〖制蛮〗（若技能均已获得，则改为摸三张牌），若自己濒死，则回复体力数和摸牌数+1。",
  ["joy__xiefang"] = "撷芳",
  [":joy__xiefang"] = "锁定技，你计算与其他角色的距离-X,你的手牌上限+X（X为全场女性角色数且至少为1）。",
  ["#joy__zhengnan-choice"] = "征南：选择获得的技能",
  ["joy__wusheng"] = "武圣",
  [":joy__wusheng"] = "回合开始时，你获得一张红色【杀】，你的红色【杀】伤害+1。",

  ["$joy__wusheng_joy__guansuo"] = "我敬佩你的勇气。",
  ["$joyex__dangxian_joy__guansuo"] = "时时居先，方可快人一步。",
  ["$ty_ex__zhiman_joy__guansuo"] = "败军之将，自当纳贡！",
}

local joy__zhaoxiang = General(extension, "joy__zhaoxiang", "shu", 4, 4, General.Female)
local joy__fuhan = fk.CreateTriggerSkill{
  name = "joy__fuhan",
  events = {fk.TurnStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@meiying") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__fuhan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    player:drawCards(n, self.name)
    if player.dead then return end

    local generals, same_g = {}, {}
    for _, general_name in ipairs(room.general_pile) do
      same_g = Fk:getSameGenerals(general_name)
      table.insert(same_g, general_name)
      same_g = table.filter(same_g, function (g_name)
        local general = Fk.generals[g_name]
        return (general.kingdom == "shu" or general.subkingdom == "shu") and general.package.extensionName == "joym"
      end)
      if #same_g > 0 then
        table.insert(generals, table.random(same_g))
      end
    end
    if #generals == 0 then return false end
    generals = table.random(generals, math.max(4, #room.alive_players))

    local skills = {}
    local choices = {}
    for _, general_name in ipairs(generals) do
      local general = Fk.generals[general_name]
      local g_skills = {}
      for _, skill in ipairs(general.skills) do
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "shu") and player.kingdom == "shu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      for _, s_name in ipairs(general.other_skills) do
        local skill = Fk.skills[s_name]
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "shu") and player.kingdom == "shu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      table.insertIfNeed(skills, g_skills)
      if #choices == 0 and #g_skills > 0 then
        choices = {g_skills[1]}
      end
    end
    if #choices > 0 then
      local result = player.room:askForCustomDialog(player, self.name,
      "packages/tenyear/qml/ChooseGeneralSkillsBox.qml", {
        generals, skills, 1, 2, "#joy__fuhan-choice", false
      })
      if result ~= "" then
        choices = json.decode(result)
      end
      room:handleAddLoseSkills(player, table.concat(choices, "|"), nil)
    end

    if not player.dead and player:isWounded() and
    table.every(room.alive_players, function(p) return p.hp >= player.hp end) then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
joy__zhaoxiang:addSkill("ty__fanghun")
joy__zhaoxiang:addSkill(joy__fuhan)
Fk:loadTranslationTable{
  ["joy__zhaoxiang"] = "赵襄",
  ["#joy__zhaoxiang"] = "拾梅鹊影",

  ["joy__fuhan"] = "扶汉",
  [":joy__fuhan"] = "限定技，回合开始时，若你有“梅影”标记，你可以移去所有“梅影”标记并摸等量的牌，然后从X张（X为存活人数且至少为4）蜀势力"..
  "武将牌中选择并获得至多两个技能（限定技、觉醒技、主公技除外）。若此时你是体力值最低的角色，你回复1点体力。"..
  '<br /><font color="red">（村：欢杀包特色，只会获得欢杀池内武将的技能）</font>',
  ["#joy__fuhan-invoke"] = "扶汉：你可以移去“梅影”标记，获得两个蜀势力武将的技能！",
  ["#joy__fuhan-choice"] = "扶汉：选择你要获得的至多2个技能",
}


local caoying = General(extension, "joy__caoying", "wei", 4, 4, General.Female)
local lingren = fk.CreateTriggerSkill{
  name = "joy__lingren",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.firstTarget and
    data.card.is_damage_card and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, 1, "#joy__lingren-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"joy__lingren_basic", "joy__lingren_trick", "joy__lingren_equip"}
    local yes = room:askForChoices(player, choices, 0, 3, self.name, "#joy__lingren-choice::" .. self.cost_data, false)
    for _, value in ipairs(yes) do
      table.removeOne(choices, value)
    end
    local right = 0
    for _, id in ipairs(to.player_cards[Player.Hand]) do
      local str = "joy__lingren_"..Fk:getCardById(id):getTypeString()
      if table.contains(yes, str) then
        right = right + 1
        table.removeOne(yes, str)
      else
        table.removeOne(choices, str)
      end
    end
    right = right + #choices
    room:sendLog{
      type = "#joy__lingren_result",
      from = player.id,
      arg = tostring(right),
    }
    if right > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.lingren = data.extra_data.lingren or {}
      table.insert(data.extra_data.lingren, self.cost_data)
    end
    if right > 1 then
      player:drawCards(2, self.name)
    end
    if right > 2 then
      local skills = {}
      if not player:hasSkill("ex__jianxiong", true) then
        table.insert(skills, "ex__jianxiong")
      end
      if not player:hasSkill("joy__xingshang", true) then
        table.insert(skills, "joy__xingshang")
      end
      room:setPlayerMark(player, self.name, skills)
      room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
    end
  end,
}
local lingren_delay = fk.CreateTriggerSkill {
  name = "#joy__lingren_delay",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or target ~= player then return false end
    local room = player.room
    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return false end
    local use = card_event.data[1]
    return use.extra_data and use.extra_data.lingren and table.contains(use.extra_data.lingren, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
  
  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("joy__lingren") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getMark("joy__lingren")
    room:setPlayerMark(player, "joy__lingren", 0)
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
  end,
}
local fujian = fk.CreateTriggerSkill {
  name = "joy__fujian",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      not table.find(player.room.alive_players, function(p) return p:isKongcheng() end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = room:getOtherPlayers(player, false)
    local to = table.random(targets)
    room:doIndicate(player.id, {to.id})
    U.viewCards(player, table.random(to.player_cards[Player.Hand], 1), self.name)
  end,
}
lingren:addRelatedSkill(lingren_delay)
caoying:addSkill(lingren)
caoying:addSkill(fujian)
caoying:addRelatedSkill("ex__jianxiong")
caoying:addRelatedSkill("joy__xingshang")
Fk:loadTranslationTable{
  ["joy__caoying"] = "曹婴",
  ["#joy__caoying"] = "龙城凤鸣",

  ["joy__lingren"] = "凌人",
  [":joy__lingren"] = "出牌阶段限一次，当你使用【杀】或伤害类锦囊牌指定目标后，你可以猜测其中一名目标角色的手牌区中是否有基本牌、锦囊牌或装备牌。"..
  "若你猜对：至少一项，此牌对其造成的伤害+1；至少两项，你摸两张牌；三项，你获得技能〖奸雄〗和〖行殇〗直到你的下个回合开始。",
  ["joy__fujian"] = "伏间",
  [":joy__fujian"] = "锁定技，结束阶段，你随机观看一名其他角色的一张手牌）。",
  ["#joy__lingren-choose"] = "凌人：你可以猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["#joy__lingren-choice"] = "凌人：猜测%dest的手牌中是否有基本牌、锦囊牌或装备牌",
  ["joy__lingren_basic"] = "有基本牌",
  ["joy__lingren_trick"] = "有锦囊牌",
  ["joy__lingren_equip"] = "有装备牌",
  ["#joy__lingren_result"] = "%from 猜对了 %arg 项",
  ["joy__lingren_delay"] = "凌人",
}

local baosanniang = General(extension, "joy__baosanniang", "shu", 3, 3, General.Female)
local joy__wuniang = fk.CreateTriggerSkill{
  name = "joy__wuniang",
  anim_type = "control",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      not table.every(player.room:getOtherPlayers(player), function(p) return p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#joy__wuniang1-choose"
    if player:usedSkillTimes("joy__xushen", Player.HistoryGame) > 0 and
      table.find(room.alive_players, function(p) return string.find(p.general, "guansuo") end) then
      prompt = "#joy__wuniang2-choose"
    end
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper), 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, player, target, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, to, "he", self.name)
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
    if not to.dead then
      to:drawCards(1, self.name)
    end
    if player:usedSkillTimes("joy__xushen", Player.HistoryGame) > 0 then
      for _, p in ipairs(room.alive_players) do
        if string.find(p.general, "guansuo") and not p.dead then
          p:drawCards(1, self.name)
        end
      end
    end
  end,
}
local joy__xushen = fk.CreateTriggerSkill{
  name = "joy__xushen",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "ty__zhennan", nil, true, false)
    if player.dead or table.find(room.alive_players, function(p) return string.find(p.general, "guansuo") end) then return end
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#joy__xushen-choose", self.name, true)
    if #to > 0 then
      to = room:getPlayerById(to[1])
      if room:askForSkillInvoke(to, self.name, nil, "#joy__xushen-invoke") then
        room:changeHero(to, "joy__guansuo", false, false, true)
      end
      if not to.dead then
        to:drawCards(3, self.name)
      end
    end
  end,
}

baosanniang:addSkill(joy__wuniang)
baosanniang:addSkill(joy__xushen)
baosanniang:addRelatedSkill("ty__zhennan")
Fk:loadTranslationTable{
  ["joy__baosanniang"] = "鲍三娘",
  ["#joy__baosanniang"] = "南中武娘",

  ["joy__wuniang"] = "武娘",
  [":joy__wuniang"] = "当你使用或打出【杀】时，你可以获得一名其他角色的一张牌，若如此做，其摸一张牌。若你已发动〖许身〗，则关索也摸一张牌。",
  ["joy__xushen"] = "许身",
  [":joy__xushen"] = "限定技，当你进入濒死状态后，你可以回复1点体力并获得技能〖镇南〗，然后如果你脱离濒死状态且关索不在场，"..
  "你可令一名其他角色选择是否用关索代替其武将并令其摸三张牌",
  ["joy__zhennan"] = "镇南",
  [":joy__zhennan"] = "当有角色使用普通锦囊牌指定目标后，若此牌目标数大于1，你可以对一名其他角色造成1点伤害。",
  ["#joy__wuniang1-choose"] = "武娘：你可以获得一名其他角色的一张牌，其摸一张牌",
  ["#joy__wuniang2-choose"] = "武娘：你可以获得一名其他角色的一张牌，其摸一张牌，关索摸一张牌",
  ["#joy__xushen-choose"] = "许身：你可以令一名其他角色摸三张牌并选择是否变身为欢乐杀关索！",
  ["#joy__xushen-invoke"]= "许身：你可以变身为欢乐杀关索！",
  
}

local zhangqiying = General(extension, "joy__zhangqiying", "qun", 3, 3, General.Female)
local zhenyi = fk.CreateViewAsSkill{
  name = "joy__zhenyi",
  anim_type = "support",
  pattern = "peach",
  prompt = "#joy__zhenyi2",
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@@faluclub", 1)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("peach")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player)
    return player.phase == Player.NotActive and player:getMark("@@faluclub") > 0
  end,
}
local zhenyi_trigger = fk.CreateTriggerSkill {
  name = "#joy__zhenyi_trigger",
  main_skill = zhenyi,
  events = {fk.AskForRetrial, fk.DamageCaused, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhenyi.name) then
      if event == fk.AskForRetrial then
        return player:getMark("@@faluspade") > 0
      elseif event == fk.DamageCaused then
        return target == player and player:getMark("@@faluheart") > 0 and data.to ~= player
      elseif event == fk.Damaged then
        return target == player and player:getMark("@@faludiamond") > 0 
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt
    if event == fk.AskForRetrial then
      prompt = "#joy__zhenyi1::"..target.id
    elseif event == fk.DamageCaused then
      prompt = "#joy__zhenyi3::"..data.to.id
    elseif event == fk.Damaged then
      prompt = "#joy__zhenyi4"
    end
    return room:askForSkillInvoke(player, zhenyi.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhenyi.name)
    if event == fk.AskForRetrial then
      room:notifySkillInvoked(player, zhenyi.name, "control")
      room:removePlayerMark(player, "@@faluspade", 1)
      local choice = room:askForChoice(player, {"joy__zhenyi_spade", "joy__zhenyi_heart"}, zhenyi.name)
      local new_card = Fk:cloneCard(data.card.name, choice == "joy__zhenyi_spade" and Card.Spade or Card.Heart, 5)
      new_card.skillName = zhenyi.name
      new_card.id = data.card.id
      data.card = new_card
      room:sendLog{
        type = "#ChangedJudge",
        from = player.id,
        to = { data.who.id },
        arg2 = new_card:toLogString(),
        arg = zhenyi.name,
      }
    elseif event == fk.DamageCaused then
      room:notifySkillInvoked(player, zhenyi.name, "offensive")
      room:removePlayerMark(player, "@@faluheart", 1)
      data.damage = data.damage + 1
    elseif event == fk.Damaged then
      room:notifySkillInvoked(player, zhenyi.name, "masochism")
      room:removePlayerMark(player, "@@faludiamond", 1)
      local cards = {}
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|basic"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|trick"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|equip"))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = zhenyi.name,
        })
      end
    end
  end,
}
local dianhua = fk.CreateTriggerSkill{
  name = "joy__dianhua",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function(self, event, target, player, data)
    local n = 1
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("@@falu"..suit) > 0 then
        n = n + 1
      end
    end
    if player.room:askForSkillInvoke(player, self.name) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForGuanxing(player, room:getNCards(self.cost_data), nil, {0, 0}, self.name)
  end,
}
zhenyi:addRelatedSkill(zhenyi_trigger)
zhangqiying:addSkill("falu")
zhangqiying:addSkill(zhenyi)
zhangqiying:addSkill(dianhua)
Fk:loadTranslationTable{
  ["joy__zhangqiying"] = "张琪瑛",
  ["#joy__zhangqiying"] = "禳祷西东",

 
  ["joy__zhenyi"] = "真仪",
  [":joy__zhenyi"] = "你可以在以下时机弃置相应的标记来发动以下效果：<br>"..
  "当一张判定牌生效前，你可以弃置“紫微”，然后将判定结果改为♠5或<font color='red'>♥5</font>；<br>"..
  "当你于回合外需要使用【桃】时，你可以弃置“后土”，然后将你的一张手牌当【桃】使用；<br>"..
  "当你对其他角色造成伤害时，你可以弃置“玉清”，此伤害+1；<br>"..
  "当你受到伤害后，你可以弃置“勾陈”，然后你从牌堆中随机获得三种类型的牌各一张。",
  ["joy__dianhua"] = "点化",
  [":joy__dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶的X张牌（X为你的标记数+1）。若如此做，你将这些牌以任意顺序放回牌堆顶。",
  
  ["#joy__zhenyi1"] = "真仪：你可以弃置♠紫微，将 %dest 的判定结果改为♠5或<font color='red'>♥5</font>",
  ["#joy__zhenyi2"] = "真仪：你可以弃置♣后土，将一张手牌当【桃】使用",
  ["#joy__zhenyi3"] = "真仪：你可以弃置<font color='red'>♥</font>玉清，对 %dest 造成的伤害+1",
  ["#joy__zhenyi4"] = "真仪：你可以弃置<font color='red'>♦</font>勾陈，从牌堆中随机获得三种类型的牌各一张",
  ["#joy__zhenyi_trigger"] = "真仪",
  ["joy__zhenyi_spade"] = "将判定结果改为♠5",
  ["joy__zhenyi_heart"] = "将判定结果改为<font color='red'>♥</font>5",
}

local joy__sunru = General(extension, "joy__sunru", "wu", 3, 3, General.Female)
local joy__xiecui = fk.CreateTriggerSkill{
  name = "joy__xiecui",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.from and not data.from.dead and data.from.phase ~= Player.NotActive and data.card then
      if data.from:getMark("joy__xiecui-turn") == 0 then
        player.room:addPlayerMark(data.from, "joy__xiecui-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#joy__xiecui-invoke:"..data.from.id..":"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage = data.damage + 1
    if  target:getHandcardNum() > target.hp and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(data.from, data.card, false)
      room:addPlayerMark(data.from, MarkEnum.AddMaxCardsInTurn, 1)
    end
  end,
}

joy__sunru:addSkill(joy__xiecui)
joy__sunru:addSkill("youxu")
Fk:loadTranslationTable{
  ["joy__sunru"] = "孙茹",
  ["#joy__sunru"] = "呦呦鹿鸣",

  ["joy__xiecui"] = "撷翠",
  [":joy__xiecui"] = "有角色在自己回合内使用牌首次造成伤害时，你可令此伤害+1。若该角色手牌数大于等于体力值，其获得此伤害牌且本回合手牌上限+1。",
  ["#joy__xiecui-invoke"] = "撷翠：你可以令 %src 对 %dest造成的伤害+1",

}

return extension
