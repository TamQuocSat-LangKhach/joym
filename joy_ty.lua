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
  events = {fk.TurnStart, fk.AfterCardsMove, fk.EnterDying},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.TurnStart then
        return target == player
      elseif event == fk.AfterCardsMove then
        if player:getMark("joy__kangge_draw-turn") < 3 then
          local n = 0
          for _, move in ipairs(data) do
            if move.to and move.toArea == Card.PlayerHand and player.room:getPlayerById(move.to):getMark("@@joy__kangge") > 0
            and player.room:getPlayerById(move.to).phase == Player.NotActive then
              n = n + #move.moveInfo
            end
          end
          if n > 0 then
            self.cost_data = n
            return true
          end
        end
      else
        return target.dying and target:getMark("@@joy__kangge") > 0 and player:getMark("joy__kangge_help-round") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EnterDying then
      return player.room:askForSkillInvoke(player, self.name, nil, "#joy__kangge-invoke::"..target.id)
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.TurnStart then
      room:notifySkillInvoked(player, self.name, "special")
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      if #targets == 0 then return end
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if p:getMark("@@joy__kangge") > 0 then
          room:setPlayerMark(p, "@@joy__kangge", 0)
        end
      end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#joy__kangge-choose", self.name, false)
      room:setPlayerMark(room:getPlayerById(tos[1]), "@@joy__kangge", 1)
    elseif event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "drawcard")
      local n = math.min(self.cost_data, 3 - player:getMark("joy__kangge_draw-turn"))
      room:addPlayerMark(player, "joy__kangge_draw-turn", n)
      player:drawCards(n, self.name)
    else
      room:notifySkillInvoked(player, "joy__kangge", "support")
      room:doIndicate(player.id, {target.id})
      room:setPlayerMark(player, "joy__kangge_help-round", 1)
      room:recover({
        who = target,
        num = 1 - target.hp,
        recoverBy = player,
        skillName = self.name,
      })
    end
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
      local choices = table.map(suits, function(s) return "log_"..s end)
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
tangji:addSkill(joy__kangge)
tangji:addSkill(joy__jielie)
Fk:loadTranslationTable{
  ["joy__tangji"] = "唐姬",
  ["joy__kangge"] = "抗歌",
  [":joy__kangge"] = "回合开始时，你令一名其他角色获得“抗歌”标记（若已有此标记则转移给其）：当该角色于其回合外获得手牌时，你摸等量的牌（每回合最多摸3张）；每轮限一次，当该角色进入濒死状态时，你可以令其将体力回复至1点。",
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
        if p:isFemale() then
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
        if p:isFemale() then
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
      local g_skills = {}
      for _, s in ipairs(Fk.generals[general_name]:getSkillNameList()) do
        local skill = Fk.skills[s]
        if skill.frequency < 4 and
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
    if player:hasSkill(self) and target and not target.dead and target == player.room.current and data.card then
      return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == target end) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#joy__xiecui-invoke:"..data.from.id..":"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage = data.damage + 1
    if not target.dead and target:getHandcardNum() > target.hp and room:getCardArea(data.card) == Card.Processing then
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 1)
      room:moveCardTo(data.card, Card.PlayerHand, target, fk.ReasonPrey, self.name)
    end
  end,
}
joy__sunru:addSkill(joy__xiecui)
joy__sunru:addSkill("youxu")
Fk:loadTranslationTable{
  ["joy__sunru"] = "孙茹",
  ["#joy__sunru"] = "呦呦鹿鸣",

  ["joy__xiecui"] = "撷翠",
  [":joy__xiecui"] = "每当一名角色于其回合内使用牌首次造成伤害时，你可令此伤害+1。若该角色手牌数大于等于体力值，其获得此伤害牌且本回合手牌上限+1。",
  ["#joy__xiecui-invoke"] = "撷翠：你可以令 %src 对 %dest造成的伤害+1",
}

local sunyi = General(extension, "joy__sunyi", "wu", 5)
local xiongyis = fk.CreateTriggerSkill{
  name = "joy__xiongyis",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#xiongyis1-invoke:::"..tostring(math.min(3, player.maxHp))
    if table.find(player.room.alive_players, function(p)
      return p.general == "joy__xushi" or p.deputyGeneral == "joy__xushi" end)
    then
      prompt = "#xiongyis2-invoke"
    end
    if player.room:askForSkillInvoke(player, self.name, nil, prompt) then
      self.cost_data = prompt
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = tonumber(string.sub(self.cost_data, 10, 10))
    if n == 1 then
      local maxHp = player.maxHp
      room:recover({
        who = player,
        num = math.min(3, maxHp) - player.hp,
        recoverBy = player,
        skillName = self.name
      })
      room:changeHero(player, "joy__xushi", false, false, true, false)
    else
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name
      })
      room:handleAddLoseSkills(player, "joy__hunzi", nil, true, false)
    end
  end,
}
local hunzi = fk.CreateTriggerSkill{
  name = "joy__hunzi",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "ex__yingzi|joy__yinghun", nil, true, false)
  end,
}
sunyi:addSkill("jiqiaos")
sunyi:addSkill(xiongyis)
sunyi:addRelatedSkill(hunzi)
sunyi:addRelatedSkill("ex__yingzi")
sunyi:addRelatedSkill("joy__yinghun")
Fk:loadTranslationTable{
  ["joy__sunyi"] = "孙翊",
  ["#joy__sunyi"] = "虓风快意",

  ["joy__xiongyis"] = "凶疑",
  [":joy__xiongyis"] = "限定技，当你处于濒死状态时，若徐氏：不在场，你可以将体力值回复至3点并将武将牌替换为徐氏；"..
  "在场，你可以将体力值回复至1点并获得技能〖魂姿〗。",
  ["joy__hunzi"] = "魂姿",
  [":joy__hunzi"] = "觉醒技，准备阶段，若你的体力为1，你减一点体力上限，然后获得“英姿”和“英魂”",

  ["$ex__yingzi_joy__sunyi"] = "骁悍果烈，威震江东！",
}

local panjun = General(extension, "joy__panjun", "wu", 3)
local guanwei = fk.CreateTriggerSkill{
  name = "joy__guanwei",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Play and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and not player:isNude() then
        local suits = {}
        local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.from == target.id then
            if table.contains(suits, use.card.suit) then
              return true
            else
              table.insert(suits, use.card.suit)
            end
          end
          return false
        end, Player.HistoryTurn)
        return #events > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#joy__guanwei-invoke::"..target.id, true)
    if #cards > 0 then
      player.room:doIndicate(player.id, {target.id})
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    if not target.dead then
      target:drawCards(2, self.name)
      target:gainAnExtraPhase(Player.Play)
    end
  end,
}
local gongqing = fk.CreateTriggerSkill{
  name = "joy__gongqing",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.from then
      return data.from:getAttackRange() >= 3 or data.damage > 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from:getAttackRange() < 3 then
      data.damage = 1
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "defensive")
    elseif data.from:getAttackRange() > 3 then
      player:drawCards(1, self.name)
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "drawcard")
    end
  end,
}
panjun:addSkill(guanwei)
panjun:addSkill(gongqing)
Fk:loadTranslationTable{
  ["joy__panjun"] = "潘濬",
  ["#joy__panjun"] = "方严疾恶",
  ["joy__guanwei"] = "观微",
  [":joy__guanwei"] = "每回合限一次，一名角色的出牌阶段结束时，若其于此回合内使用过相同花色的牌，你可弃置一张牌，令其摸两张牌，然后其获得一个额外的出牌阶段。",
  ["joy__gongqing"] = "公清",
  [":joy__gongqing"] = "锁定技，当你受到伤害时，若伤害来源攻击范围小于3，则你只受到1点伤害；若伤害来源攻击范围不小于3，你摸一张牌。",
  ["#joy__guanwei-invoke"] = "观微：你可以弃置一张牌，令 %dest 摸两张牌并执行一个额外的出牌阶段",
}

local xushao = General(extension, "joy__xushao", "qun", 4)

local pingjian_skills = {
  -- 出牌阶段
  ["play"] =
  {
  "nya__lijian","nya__guose","nya__jieyi","joy__daoyao","joy__tuantu","joyex__lijian","joy__shenglun","joyex__qiangxi",
  "joy__jueyan","joy__huairou","joy__qice","joy__kuangbi","joy__mingjian","joy__huoxin","joy__poxi","shencai","joy__yingba","ol__xuehen",
  "joy__xingwu","joy__guolun","joysp__juesi","joy__lihun","joy_mou__kurou","xieju","duanfa","jiezhen","joy__mingjian",
  "ty__gushe","anzhi","zhuren","jinghe","jinhui","joy__wengua","kurou","joy__duwu","joy__anguo","joy__god_huishi","joy__zuoxing",
  "zhanhuo","joy__jianshu","zunwei","joysp__weikui","joy__manwang","joy__jixu","joy__xiaowu","joy__channi","joy__quanji","joy__paiyi",
  "ty__zhongjian","joy__weilie","joy__yanjiao","joyex__zhiheng","joyex__jieyi","joyex__wanrong","joyex__qixi","joy__xianzhu","joy__youyan",
  "limu","joy_mou__duojing","joy_mou__luanji","joyex__qingnang","joy__difa","ty_ex__wurong","joyex__changbiao","joy_mou__qingzheng","joy__chenglue","joy_mou__rende",
  },
  --受到伤害后 
  [fk.Damaged] =
  {
    "joyex__fankui","ex__yiji","joyex__jianxiong","joy__fangzhu","joy__zhiyu","huituo","joy__jieying","joy__guixin",
    "joy__chouce","ex__jianxiong","yuqi","qianlong","lundao","joy_mou__jianxiong","joy__shunshi","joy__chengxiang",
    "wangxi","joy__jilei","joy__xingshen","ex__ganglie","joy__benyu","joy__shefu","joy__baobian","zhichi","joy__quanji","joy__jiushi",
  },
  --结束阶段
  [fk.EventPhaseStart] =
  {
    "nya__biyue","nya__miji","joyex__biyue","ty_ex__zhenjun","joy__jujian","joy__jieying","joy__meihun","joy__shenfu","joy__benghuai",
    "mozhi","joy__youdi","joy__fujian","joy__dianhua","gongxiu","guanyue","ex__biyue","zhiyan","zhukou","fuxue","nya__luoshen",
    "zhengu","joy__zuilun","joy__yingyu","joy__guanxing","joysp__kunfen","joysp__lizhan","joy__xunxun","joy__shefu","joy__yishe","joy_mou__shipo","joy__zhuihuan",
  }
}

local getPingjianSkills = function (player, event)
  local used_skills = player:getTableMark("joy__pingjian_used")
  local e = event and event or "play"
  return table.filter(pingjian_skills[e], function (skill_name)
    local sk = Fk.skills[skill_name]
    return sk and not table.contains(used_skills, skill_name) and not player:hasSkill(sk, true)
  end)
end

---@param player ServerPlayer
local addTYPingjianSkill = function(player, skill_name)
  local room = player.room
  local skill = Fk.skills[skill_name]
  if skill == nil or player:hasSkill(skill_name, true) then return false end
  room:handleAddLoseSkills(player, skill_name, nil)
  local skills = player:getTableMark("joy__pingjian_skills")
  table.insertIfNeed(skills, skill_name)
  room:setPlayerMark(player, "joy__pingjian_skills", skills)
  local pingjian_skill_times = player:getTableMark("joy__pingjian_skill_times")
  table.insert(pingjian_skill_times, {skill_name, player:usedSkillTimes(skill_name)})
  for _, s in ipairs(skill.related_skills) do
    table.insert(pingjian_skill_times, {s.name, player:usedSkillTimes(s.name)})
  end
  room:setPlayerMark(player, "joy__pingjian_skill_times", pingjian_skill_times)
end

---@param player ServerPlayer
local removeTYPingjianSkill = function(player, skill_name)
  local room = player.room
  local skill = Fk.skills[skill_name]
  if skill == nil then return false end
  room:handleAddLoseSkills(player, "-" .. skill_name, nil)
  local skills = player:getTableMark("joy__pingjian_skills")
  table.removeOne(skills, skill_name)
  room:setPlayerMark(player, "joy__pingjian_skills", skills)
  local invoked = false
  local pingjian_skill_times = player:getTableMark("joy__pingjian_skill_times")
  local record_copy = {}
  for _, pingjian_record in ipairs(pingjian_skill_times) do
    if #pingjian_record == 2 then
      local record_name = pingjian_record[1]
      if record_name == skill_name or not table.every(skill.related_skills, function (s)
          return s.name ~= record_name end) then
        if player:usedSkillTimes(record_name) > pingjian_record[2] then
          invoked = true
        end
      else
        table.insert(record_copy, pingjian_record)
      end
    end
  end
  room:setPlayerMark(player, "joy__pingjian_skill_times", record_copy)

  if invoked then
    local used_skills = player:getTableMark("joy__pingjian_used")
    table.insertIfNeed(used_skills, skill_name)
    room:setPlayerMark(player, "joy__pingjian_used", used_skills)
  end
end

local joy__pingjian = fk.CreateActiveSkill{
  name = "joy__pingjian",
  prompt = "#joy__pingjian-active",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local skills = getPingjianSkills(player)
    if #skills == 0 then return false end
    local choices = table.random(skills, 3)
    local skill_name = room:askForChoice(player, choices, self.name, "#joy__pingjian-choice", true)
    local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase)
    if phase_event ~= nil then
      addTYPingjianSkill(player, skill_name)
      phase_event:addCleaner(function()
        removeTYPingjianSkill(player, skill_name)
      end)
    end
  end,
}
local joy__pingjian_trigger = fk.CreateTriggerSkill{
  name = "#joy__pingjian_trigger",
  events = {fk.Damaged, fk.EventPhaseStart},
  main_skill = joy__pingjian,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(joy__pingjian) or player ~= target then return false end
    if event == fk.Damaged then
      return true
    elseif event == fk.EventPhaseStart then
      return player.phase == Player.Finish
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, joy__pingjian.name)
    player:broadcastSkillInvoke(joy__pingjian.name)
    local skills = getPingjianSkills(player, event)
    if #skills == 0 then return false end
    local choices = table.random(skills, 3)
    local skill_name = room:askForChoice(player, choices, joy__pingjian.name, "#joy__pingjian-choice", true)
    local skill = Fk.skills[skill_name]
    if skill == nil then return false end
    local _skill = skill
    if not _skill:isInstanceOf(TriggerSkill) then
      _skill = table.find(_skill.related_skills, function (s)
        return s:isInstanceOf(TriggerSkill)
      end)
      if not _skill then return end
    end

    addTYPingjianSkill(player, skill_name)
    if _skill:triggerable(event, target, player, data) then
      _skill:trigger(event, target, player, data)
    end
    removeTYPingjianSkill(player, skill_name)
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and not player.faceup
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.jiushi_check = true
  end,
}
local joy__pingjian_invalidity = fk.CreateInvaliditySkill {
  name = "#joy__pingjian_invalidity",
  invalidity_func = function(self, player, skill)
    local pingjian_skill_times = player:getTableMark("joy__pingjian_skill_times")
    return table.find(pingjian_skill_times, function (pingjian_record)
      if #pingjian_record == 2 then
        local skill_name = pingjian_record[1]
        if skill.name == skill_name or not table.every(skill.related_skills, function (s)
          return s.name ~= skill_name end) then
            return player:usedSkillTimes(skill_name) > pingjian_record[2]
        end
      end
    end)
  end
}

joy__pingjian:addRelatedSkill(joy__pingjian_trigger)
joy__pingjian:addRelatedSkill(joy__pingjian_invalidity)
xushao:addSkill(joy__pingjian)

Fk:loadTranslationTable{
  ["joy__xushao"] = "许劭",
  ["#joy__xushao"] = "识人读心",
  
  ["joy__pingjian"] = "评荐",
  ["#joy__pingjian_trigger"] = "评荐",
  [":joy__pingjian"] = "出牌阶段，或结束阶段，或当你受到伤害后，你可以从对应时机的技能池中随机抽取三个技能，"..
    "然后你选择并视为拥有其中一个技能直到时机结束（每个技能限发动一次）。",
  ["#joy__pingjian-active"] = "评荐：从三个出牌阶段的技能中选择一个学习",
  ["#joy__pingjian-choice"] = "评荐：选择要学习的技能",
}






return extension
