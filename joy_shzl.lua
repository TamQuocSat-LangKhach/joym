local extension = Package("joy_shzl")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_shzl"] = "欢乐-神话再临",
}

local U = require "packages/utility/utility"


local caopi = General(extension, "joy__caopi", "wei", 3)
local xingshang = fk.CreateTriggerSkill{
  name = "joy__xingshang",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("fangzhu")
    local cards = target:getCardIds{Player.Hand, Player.Equip}
    if #cards > 0 then
      local dummy = Fk:cloneCard'slash'
      dummy:addSubcards(cards)
      room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    end
    if not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
local fangzhu = fk.CreateTriggerSkill{
  name = "joy__fangzhu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#joy__fangzhu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("fangzhu")
    local to = player.room:getPlayerById(self.cost_data)
    to:turnOver()
    if not to.dead then
      to:drawCards(1, self.name)
    end
  end,
}
caopi:addSkill(xingshang)
caopi:addSkill(fangzhu)
caopi:addSkill("songwei")
Fk:loadTranslationTable{
  ["joy__caopi"] = "曹丕",
  ["joy__xingshang"] = "行殇",
  [":joy__xingshang"] = "当其他角色死亡时，你可以获得其所有牌并摸一张牌。",
  ["joy__fangzhu"] = "放逐",
  [":joy__fangzhu"] = "当你受到伤害后，你可以令一名其他角色翻面，然后该角色摸一张牌。",
  ["#joy__fangzhu-choose"] = "放逐：你可以令一名其他角色翻面，然后其摸一张牌",
}

local yanyan = General(extension, "joy__yanyan", "shu", 4)
local joy__juzhan = fk.CreateTriggerSkill{
  name = "joy__juzhan",
  mute = true,
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self) and data.card.trueName == "slash") then return false end
    if event == fk.TargetConfirmed then
      return player.id ~= data.from and not player.room:getPlayerById(data.from).dead
    else
      return not player.room:getPlayerById(data.to):isNude()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.TargetConfirmed then
        room:notifySkillInvoked(player, self.name, "defensive")
        local from = room:getPlayerById(data.from)
        player:drawCards(1, self.name)
        if from.dead then return end
        from:drawCards(1, self.name)
        if from.dead then return end
        local mark = U.getMark(from, "@@joy__juzhan-turn")
        table.insertIfNeed(mark, player.id)
        room:setPlayerMark(from, "@@joy__juzhan-turn", mark)
    else
        room:notifySkillInvoked(player, self.name, "control")
        local to = room:getPlayerById(data.to)
        room:moveCardTo(room:askForCardChosen(player, to, "he", self.name), Card.PlayerHand, player, fk.ReasonPrey, self.name, "", false, player.id)
        local mark = U.getMark(player, "joy__juzhan_red-turn")
        table.insertIfNeed(mark, to.id)
        room:setPlayerMark(player, "joy__juzhan_red-turn", mark)
    end
  end,
}
local joy__juzhan_prohibit = fk.CreateProhibitSkill{
  name = "#joy__juzhan_prohibit",
  is_prohibited = function(self, from, to, card)
    return table.contains(U.getMark(from, "@@joy__juzhan-turn"), to.id)
    or (card and card.color == Card.Red and card.trueName == "slash" and table.contains(U.getMark(from, "joy__juzhan_red-turn"), to.id))
  end,
}
joy__juzhan:addRelatedSkill(joy__juzhan_prohibit)
yanyan:addSkill(joy__juzhan)
Fk:loadTranslationTable{
  ["joy__yanyan"] = "严颜",
  ["#joy__yanyan"] = "断头将军",

  ["joy__juzhan"] = "拒战",
  [":joy__juzhan"] = "当你成为其他角色使用【杀】的目标后，你可以与其各摸一张牌，然后其本回合不能再对你使用牌；当你使用【杀】指定一名角色为目标后，你可以获得其一张牌，然后你本回合不能对其使用红色【杀】。",
  ["@@joy__juzhan-turn"] = "拒战",

  ["~yanyan"] = "宁可断头死，安能屈膝降！",
  ["$joy__juzhan1"] = "砍头便砍头，何为怒耶！",
  ["$joy__juzhan2"] = "我州但有断头将军，无降将军也！",
}

local godsimayi = General(extension, "joy__godsimayi", "god", 3)
local joy__renjie = fk.CreateTriggerSkill{
  name = "joy__renjie",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.AfterCardsMove, fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.Damaged then
        return target == player
      elseif event == fk.AfterCardsMove then
        if player.phase == Player.Discard then
          for _, move in ipairs(data) do
            if move.from == player.id and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand then
                  return true
                end
              end
            end
          end
        end
      else
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    if event == fk.Damaged then
      room:addPlayerMark(player, "@godsimayi_bear", data.damage)
    elseif event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              n = n + 1
            end
          end
        end
      end
    else
      n = 1
    end
    room:addPlayerMark(player, "@godsimayi_bear", n)
  end,
}
local jilue = fk.CreateActiveSkill{
  name = "joy__jilue",
  mute = true,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  prompt = "#joy__jilue-wansha",
  can_use = function(self, player)
    return player:getMark("@godsimayi_bear") > 0 and not player:hasSkill("joy__wansha", true)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:removePlayerMark(player, "@godsimayi_bear", 1)
    player:broadcastSkillInvoke("wansha")
    room:notifySkillInvoked(player, "jilue", "offensive")
    room:handleAddLoseSkills(player, "joy__wansha")
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(player, "-joy__wansha")
    end)
  end
}
local jilue_trigger = fk.CreateTriggerSkill{
  name = "#joy__jilue_trigger",
  mute = true,
  main_skill = jilue,
  events = {fk.AskForRetrial, fk.Damaged, fk.CardUsing, fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterSkillEffect then
      return data == jilue and target == player and player:usedSkillTimes("joy__jilue", Player.HistoryTurn) == 1 and not player.dead
    elseif player:hasSkill(jilue) and player:getMark("@godsimayi_bear") > 0 then
      if event == fk.AskForRetrial then
        return not player:isNude()
      elseif event == fk.Damaged then
        return target == player
      elseif event == fk.CardUsing then
        return target == player and data.card:isCommonTrick()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AskForRetrial then
      local card = room:askForResponse(player, "ex__guicai", ".|.|.|hand,equip", "#joy__jilue-guicai::" .. target.id..":"..data.reason, true)
      if card ~= nil then
        self.cost_data = card
        return true
      end
    elseif event == fk.Damaged then
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#joy__jilue-fangzhu", "joyex__fangzhu", true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    elseif event == fk.CardUsing then
      return room:askForSkillInvoke(player, "jizhi", nil, "#joy__jilue-jizhi")
    else
      return room:askForSkillInvoke(player, self.name, nil, "#joy__jilue-draw")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@godsimayi_bear", 1)
    room:notifySkillInvoked(player, "jilue", (event == fk.CardUsing or event == fk.AfterSkillEffect) and "drawcard" or "control")
    if event == fk.AskForRetrial then
      player:broadcastSkillInvoke("guicai")
      room:retrial(self.cost_data, player, data, "uicai")
    elseif event == fk.Damaged then
      player:broadcastSkillInvoke("fangzhu")
      local to = player.room:getPlayerById(self.cost_data)
      to:drawCards(1, "joyex__fangzhu")
      if not to.dead then
        to:turnOver()
      end
    elseif event == fk.CardUsing then
      player:broadcastSkillInvoke("jizhi")
      player:drawCards(1, "jizhi")
    else
      player:drawCards(1, "joy__jilue")
    end
  end,
}
jilue:addRelatedSkill(jilue_trigger)

local joy__wansha = fk.CreateProhibitSkill{
  name = "joy__wansha",
  frequency = Skill.Compulsory,
  prohibit_use = function(self, player, card)
    return card and card.name == "peach" and table.find(Fk:currentRoom().alive_players, function (p)
      return p.phase ~= Player.NotActive and p ~= player and p:hasSkill(self)
    end)
  end,
}
godsimayi:addRelatedSkill(joy__wansha)

godsimayi:addSkill(joy__renjie)
godsimayi:addSkill("lianpo")
godsimayi:addSkill(jilue)
godsimayi:addRelatedSkill("ex__guicai")
godsimayi:addRelatedSkill("joyex__fangzhu")
godsimayi:addRelatedSkill("jizhi")
godsimayi:addRelatedSkill("joy__wansha")
Fk:loadTranslationTable{
  ["joy__godsimayi"] = "神司马懿",
  ["#joy__godsimayi"] = "晋国之祖",
  ["joy__renjie"] = "忍戒",
  [":joy__renjie"] = "锁定技，游戏开始时，你获得1枚“忍”标记；当你受到伤害后/于弃牌阶段弃置手牌后，你获得X枚“忍”（X为伤害值/你弃置的手牌数）。",
  ["joy__jilue"] = "极略",
  [":joy__jilue"] = "你可以弃置1枚“忍”，发动下列一项技能：〖鬼才〗、〖放逐〗、〖集智〗、〖完杀〗；你每回合首次发动〖极略〗时可摸一张牌。",
  
  ["#joy__jilue-jizhi"] = "极略：可弃1枚“忍”标记，发动〖集智〗：摸一张牌",
  ["#joy__jilue-wansha"] = "极略：你可以弃1枚“忍”标记，获得〖完杀〗直到回合结束",
  ["#joy__jilue-fangzhu"] = "极略：可弃1枚“忍”标记，发动〖放逐〗：令一名其他角色翻面并摸一张牌",
  ["#joy__jilue-guicai"] = "极略：可弃1枚“忍”标记，发动〖鬼才〗：修改 %dest 的“%arg”判定",
  ["#joy__jilue-draw"] = "极略：你可以摸一张牌",
  ["#joy__jilue_trigger"] = "极略",

  ["joy__wansha"] = "完杀",
  [":joy__wansha"] = "锁定技，其他角色无法于你的回合内使用【桃】",
}

local joy__godliubei = General(extension, "joy__godliubei", "god", 6)
local joy__longnu = fk.CreateTriggerSkill{
  name = "joy__longnu",
  events = {fk.EventPhaseStart},
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"joy__longnu_red", "joy__longnu_black"}, self.name)
    local mark = U.getMark(player, "@joy__longnu-turn")
    local color = string.sub(choice, 13, -1)
    table.insertIfNeed(mark, color)
    room:setPlayerMark(player, "@joy__longnu-turn", mark)
    for _, id in ipairs(player:getCardIds("h")) do
      Fk:filterCard(id, player)
    end
    if color == "red" then
      room:loseHp(player, 1, self.name)
      if player.dead then return end
      player:drawCards(2, self.name)
    else
      room:changeMaxHp(player, -1)
    end
  end,
}
local joy__longnu_filter = fk.CreateFilterSkill{
  name = "#joy__longnu_filter",
  card_filter = function(self, card, player)
    if player:hasSkill("joy__longnu") and table.contains(player.player_cards[Player.Hand], card.id) then
      local mark = U.getMark(player, "@joy__longnu-turn")
      return table.contains(mark, card:getColorString())
    end
  end,
  view_as = function(self, card, player)
    local c = Fk:cloneCard(card.color == Card.Red and "fire__slash" or "thunder__slash", card.suit, card.number)
    c.skillName = "joy__longnu"
    return c
  end,
}
local joy__longnu_targetmod = fk.CreateTargetModSkill{
  name = "#joy__longnu_targetmod",
  bypass_distances =  function(self, player, skill, card, to)
    return card and card.name == "fire__slash" and table.contains(card.skillNames, "joy__longnu")
  end,
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.name == "thunder__slash" and table.contains(card.skillNames, "joy__longnu")
  end,
}
joy__longnu:addRelatedSkill(joy__longnu_filter)
joy__longnu:addRelatedSkill(joy__longnu_targetmod)
joy__godliubei:addSkill(joy__longnu)
local joy__jieying = fk.CreateTriggerSkill{
  name = "joy__jieying",
  events = {fk.BeforeChainStateChange, fk.EventPhaseStart, fk.GameStart, fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.BeforeChainStateChange then
      return target == player and player.chained
    elseif event == fk.EventPhaseStart then
      return target == player and player.phase == Player.Finish and table.find(player.room.alive_players, function(p)
        return p ~= player and not p.chained
      end)
    elseif event == fk.DamageInflicted then
      return target == player
    else
      return not player.chained
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.GameStart then
      player:setChainState(true)
    elseif event == fk.BeforeChainStateChange then
      return true
    elseif event == fk.DamageInflicted then
      player:drawCards(1, self.name)
    else
      local room = player.room
      local targets = table.filter(room.alive_players, function(p)
        return p ~= player and not p.chained
      end)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#joy__jieying-target", self.name, true)
      if #tos > 0 then
        room:getPlayerById(tos[1]):setChainState(true)
      end
    end
  end,
}
local joy__jieying_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__jieying_maxcards",
  correct_func = function(self, player)
    if player.chained then
      local num = #table.filter(Fk:currentRoom().alive_players, function(p)
        return p:hasSkill(joy__jieying)
      end)
      return 2 * num
    end
  end,
}
joy__jieying:addRelatedSkill(joy__jieying_maxcards)
joy__godliubei:addSkill(joy__jieying)
Fk:loadTranslationTable{
  ["joy__godliubei"] = "神刘备",
  ["#joy__godliubei"] = "誓守桃园义",

  ["joy__longnu"] = "龙怒",
  [":joy__longnu"] = "锁定技，出牌阶段开始时，你须选一项：1.失去1点体力并摸两张牌，你的红色手牌于本回合均视为无距离限制的火【杀】；2.扣减1点体力上限，你的黑色手牌于本回合均视为无次数限制的雷【杀】。",
  ["joy__jieying"] = "结营",
  [":joy__jieying"] = "锁定技，你始终处于横置状态；每当你受到伤害时，摸一张牌；处于连环状态的角色手牌上限+2；结束阶段，你可以横置一名其他角色。",

  ["#joy__longnu_filter"] = "龙怒",
  ["joy__longnu_red"] = "失去体力并摸牌，红色手牌视为火杀",
  ["joy__longnu_black"] = "减体力上限，黑色手牌视为雷杀",
  ["@joy__longnu-turn"] = "龙怒",
  ["#joy__jieying-target"] = "结营：你可以横置一名其他角色",
}








return extension