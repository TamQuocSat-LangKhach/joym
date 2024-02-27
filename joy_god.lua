local extension = Package("joy_god")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_god"] = "欢乐-神",
}

-- 神武将，包括原神武将基础上的修改，以及原创神武将，不包含限时地主

local U = require "packages/utility/utility"


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
local joy__jilue = fk.CreateTriggerSkill{
  name = "joy__jilue",
  events = {fk.AskForRetrial, fk.Damaged, fk.CardUsing, fk.EnterDying, fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterSkillEffect then
      return data == self and target == player and player:usedSkillTimes("joy__jilue", Player.HistoryTurn) == 1 and not player.dead
    elseif player:hasSkill(self) and player:getMark("@godsimayi_bear") > 0 then
      if event == fk.AskForRetrial then
        return not player:isNude()
      elseif event == fk.Damaged then
        return target == player
      elseif event == fk.CardUsing then
        return target == player and data.card:isCommonTrick()
      elseif event == fk.EnterDying then
        return player == player.room.current and not player:hasSkill("joy__wansha", true)
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
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#joy__jilue-fangzhu", "joy__fangzhu", true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      local list = { [fk.CardUsing] = "jizhi", [fk.EnterDying] = "wansha", [fk.AfterSkillEffect] = "draw", }
      return room:askForSkillInvoke(player, self.name, nil, "#joy__jilue-"..list[event])
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
      to:drawCards(1, "joy__fangzhu")
      if not to.dead then
        to:turnOver()
      end
    elseif event == fk.CardUsing then
      player:broadcastSkillInvoke("jizhi")
      player:drawCards(1, "jizhi")
    elseif event == fk.EnterDying then
      data.extra_data = data.extra_data or {}
      data.extra_data.joy__jilue_wansha = player.id
      room:handleAddLoseSkills(player, "joy__wansha")
    else
      player:drawCards(1, "joy__jilue")
    end
  end,
}
local joy__jilue_delay = fk.CreateTriggerSkill{
  name = "#joy__jilue_delay",
  mute = true,
  events = {fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.joy__jilue_wansha == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-joy__wansha")
  end,
}
joy__jilue:addRelatedSkill(joy__jilue_delay)
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
godsimayi:addSkill(joy__jilue)
godsimayi:addRelatedSkill("ex__guicai")
godsimayi:addRelatedSkill("joy__fangzhu")
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
  ["#joy__jilue-wansha"] = "极略：你可以弃1枚“忍”标记，获得〖完杀〗直到濒死结算结束",
  ["#joy__jilue-fangzhu"] = "极略：可弃1枚“忍”标记，发动〖放逐〗：令一名其他角色翻面并摸一张牌",
  ["#joy__jilue-guicai"] = "极略：可弃1枚“忍”标记，发动〖鬼才〗：修改 %dest 的“%arg”判定",
  ["#joy__jilue-draw"] = "极略：你可以摸一张牌",
  ["#joy__jilue_delay"] = "极略",

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

-- OL活动场

local godzhenji = General(extension, "joy__godzhenji", "god", 3, 3, General.Female)
local joy__shenfu = fk.CreateTriggerSkill{
  name = "joy__shenfu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    if player:getHandcardNum() % 2 == 1 then
      while true do
        local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#shenfu-damage", self.name, true)
        if #tos == 0 then break end
        n = n + 1
        local to = room:getPlayerById(tos[1])
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
        if not to.dead then
          break
        end
      end
    else
      while true do
        local tos = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
          return p:getMark("joy__shenfu-turn") == 0 end), Util.IdMapper), 1, 1, "#shenfu-hand", self.name, true)
        if #tos == 0 then break end
        n = n + 1
        local to = room:getPlayerById(tos[1])
        room:setPlayerMark(to, "joy__shenfu-turn", 1)
        if to:isKongcheng() then
          to:drawCards(1, self.name)
        else
          local choice = room:askForChoice(player, {"shenfu_draw", "shenfu_discard"}, self.name)
          if choice == "shenfu_draw" then
            to:drawCards(1, self.name)
          else
            local card = room:askForCardsChosen(player, to, 1, 1, "h", self.name)
            room:throwCard(card, self.name, to, player)
          end
        end
        if to:getHandcardNum() ~= to.hp then
          break
        end
      end
    end
    if not player.dead and n > 0 then
      player:drawCards(math.min(n, 5), self.name)
    end
  end,
}
local joy__qixian = fk.CreateTriggerSkill{
  name = "joy__qixian",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true, ".", "#joy__qixian-card")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(self.name, self.cost_data, false, self.name)
  end,
}
local joy__qixian_delay = fk.CreateTriggerSkill{
  name = "#joy__qixian_delay",
  mute = true,
  events = {fk.TurnEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile("joy__qixian") > 0
  end,
  on_use = function(self, event, target, player, data)
    local dummy = Fk:cloneCard("slash")
    dummy:addSubcards(player:getPile("joy__qixian"))
    player.room:obtainCard(player, dummy, false, fk.ReasonPrey)
  end,
}
local joy__qixian_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__qixian_maxcards",
  frequency = Skill.Compulsory,
  fixed_func = function (self, player)
    if player:hasSkill(joy__qixian) then
      return 7
    end
  end,
}
local joy__feifu = fk.CreateViewAsSkill{
  name = "joy__feifu",
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
godzhenji:addSkill(joy__shenfu)
joy__qixian:addRelatedSkill(joy__qixian_maxcards)
joy__qixian:addRelatedSkill(joy__qixian_delay)
godzhenji:addSkill(joy__qixian)
godzhenji:addSkill(joy__feifu)
Fk:loadTranslationTable{
  ["joy__godzhenji"] = "神甄姬",
  ["joy__shenfu"] = "神赋",
  [":joy__shenfu"] = "结束阶段，如果你的手牌数量为：奇数，可对一名其他角色造成1点雷电伤害，若造成其死亡，你可重复此流程；"..
  "偶数，可令一名角色摸一张牌或你弃置其一张手牌，若执行后该角色的手牌数等于其体力值，你可重复此流程（不能对本回合指定过的目标使用）。"..
  "然后你摸X张牌（X为你本回合执行〖神赋〗流程的次数，最大为5）。",
  ["joy__qixian"] = "七弦",
  [":joy__qixian"] = "锁定技，你的手牌上限为7。出牌阶段结束时，你可以将一张手牌移出游戏直到回合结束。",
  ["#joy__qixian_delay"] = "七弦",
  ["#joy__qixian-card"] = "七弦：你可以将一张手牌移出游戏直到回合结束",
  ["joy__feifu"] = "飞凫",
  [":joy__feifu"] = "你可以将一张黑色牌当【闪】使用或打出。",
}

-- 欢乐杀原创

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

local goddianwei = General(extension, "joy__goddianwei", "god", 5)

local joy__shenwei = fk.CreateTriggerSkill{
  name = "joy__shenwei",
  anim_type = "support",
  events = {fk.TurnStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return target == player and player:hasSkill(self) and
      table.find(player.room.alive_players, function (p) return p:getMark("@@joy__secure") == 0 end)
    else
      return not player.dead and target:getMark("@@joy__secure") == player.id
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.TurnStart then
      local targets = table.filter(player.room.alive_players, function (p) return p:getMark("@@joy__secure") == 0 end)
      if #targets == 0 then return false end
      local tos = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#joy__shenwei-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    else
      return player.room:askForSkillInvoke(target, self.name, nil, "#joy__shenwei-invoke:"..player.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:setPlayerMark(room:getPlayerById(self.cost_data), "@@joy__secure", player.id)
    else
      room:setPlayerMark(target, "@@joy__secure", 0)
      room.logic:trigger("fk.MarkChanged", target, { name = "@@joy__secure", num = -1 })
      room:damage{
        from = data.from,
        to = player,
        damage = data.damage,
        damageType = data.damageType,
        skillName = data.skillName,
        chain = data.chain,
        card = data.card,
      }
      return true
    end
  end,

  refresh_events = {fk.Deathed, fk.EventLoseSkill},
  can_refresh = function (self, event, target, player, data)
    if event == fk.Deathed then
      return target == player and player:hasSkill(self, true, true)
    else
      return target == player and data == self
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@@joy__secure") == player.id then
        room:setPlayerMark(p, "@@joy__secure", 0)
      end
    end
  end,
}
goddianwei:addSkill(joy__shenwei)

local joy__elai = fk.CreateTriggerSkill{
  name = "joy__elai",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {"fk.MarkChanged"},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.name == "@@joy__secure" and data.num < 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if player:isWounded() then table.insert(choices, "recover") end
    local targets = table.filter(room.alive_players, function (p) return player:inMyAttackRange(p) end)
    if #targets > 0 then
      table.insert(choices, "joy__elai_damage")
    end
    if #choices == 0 then return false end
    table.insert(choices, "Cancel")
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "joy__elai_damage" then
      local tos = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#joy__elai-choose", self.name, false)
      room:damage{
        from = player,
        to = room:getPlayerById(tos[1]),
        damage = 1,
        skillName = self.name,
      }
    elseif choice == "recover" then
      room:recover { num = 1, skillName = self.name, who = player, recoverBy = player }
    end
  end,
}
goddianwei:addSkill(joy__elai)

local joy__kuangxi = fk.CreateTriggerSkill{
  name = "joy__kuangxi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and
    table.find(player.room.alive_players, function (p) return p:getMark("@@joy__secure") > 0 end)
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
goddianwei:addSkill(joy__kuangxi)

Fk:loadTranslationTable{
  ["joy__goddianwei"] = "神典韦",

  ["joy__shenwei"] = "神卫",
  [":joy__shenwei"] = "回合开始时，你可以令一名没有“卫”标记的角色获得“卫”标记，该角色受到伤害时，可以移除此标记，将此伤害转移给你。",
  ["@@joy__secure"] = "卫",
  ["#joy__shenwei-choose"] = "神卫：令一名角色获得“卫”标记",
  ["#joy__shenwei-invoke"] = "神卫：你可以将伤害转移给 %src",

  ["joy__elai"] = "恶来",
  [":joy__elai"] = "锁定技，当一名角色的“卫”标记移除时，你可以选一项：1.回复一点体力；2.对攻击范围内一名角色造成1点伤害。",
  ["joy__elai_damage"] = "对攻击范围内一名角色造成伤害",
  ["#joy__elai-choose"] = "恶来：对攻击范围内一名角色造成1点伤害",

  ["joy__kuangxi"] = "狂袭",
  [":joy__kuangxi"] = "锁定技，每当你造成伤害时，若场上存在“卫”标记，此伤害+1。",
}

local godzhaoyun = General(extension, "joy__godzhaoyun", "god", 2)
local juejing = fk.CreateTriggerSkill{
  name = "joy__juejing",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying, fk.AfterDying},
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local juejing_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__juejing_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(juejing.name) then
      return 3
    end
  end
}
juejing:addRelatedSkill(juejing_maxcards)
local longhun = fk.CreateViewAsSkill{
  name = "joy__longhun",
  pattern = "peach,slash,jink,nullification",
  card_filter = function(self, to_select, selected)
    if #selected == 2 then
      return false
    elseif #selected == 1 then
      return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]))
    else
      local suit = Fk:getCardById(to_select).suit
      local c
      if suit == Card.Heart then
        c = Fk:cloneCard("peach")
      elseif suit == Card.Diamond then
        c = Fk:cloneCard("fire__slash")
      elseif suit == Card.Club then
        c = Fk:cloneCard("jink")
      elseif suit == Card.Spade then
        c = Fk:cloneCard("nullification")
      else
        return false
      end
      return (Fk.currentResponsePattern == nil and c.skill:canUse(Self, c)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
    end
  end,
  view_as = function(self, cards)
    if #cards == 0 or #cards > 2 then
      return nil
    end
    local suit = Fk:getCardById(cards[1]).suit
    local c
    if suit == Card.Heart then
      c = Fk:cloneCard("peach")
    elseif suit == Card.Diamond then
      c = Fk:cloneCard("fire__slash")
    elseif suit == Card.Club then
      c = Fk:cloneCard("jink")
    elseif suit == Card.Spade then
      c = Fk:cloneCard("nullification")
    else
      return nil
    end
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    local num = #use.card.subcards
    if num == 2 then
      local suit = Fk:getCardById(use.card.subcards[1]).suit
      if suit == Card.Diamond then
        use.additionalDamage = (use.additionalDamage or 0) + 1
        player:drawCards(1, self.name)
      elseif suit == Card.Heart then
        use.additionalRecover = (use.additionalRecover or 0) + 1
        player:drawCards(1, self.name)
      end
    end
  end,
}
local longhun_obtaincard = fk.CreateTriggerSkill{
  name = "#joy__longhun_obtaincard",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "joy__longhun") and #data.card.subcards == 2 and Fk:getCardById(data.card.subcards[1]).color == Card.Black
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room.current
      if from and not from.dead and not from:isNude() then
        room:doIndicate(player.id, {from.id})
        local card = room:askForCardChosen(player, from, "he", self.name)
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
  end,
}
longhun:addRelatedSkill(longhun_obtaincard)
godzhaoyun:addSkill(juejing)
godzhaoyun:addSkill(longhun)
Fk:loadTranslationTable{
  ["joy__godzhaoyun"] = "神赵云",
  ["#joy__godzhaoyun"] = "神威如龙",

  ["joy__juejing"] = "绝境",
  [":joy__juejing"] = "锁定技，你的手牌上限+3；当你进入濒死状态时或你的濒死结算结束后，你摸一张牌。",
  ["joy__longhun"] = "龙魂",
  ["#joy__longhun_obtaincard"] = "龙魂",
  [":joy__longhun"] = "你可以将至多两张你的同花色的牌按以下规则使用或打出：红桃当【桃】，方块当火【杀】，梅花当【闪】，黑桃当【无懈可击】。"..
  "若你以此法使用或打出了两张：红色牌，此牌回复伤害基数+1，且你摸一张牌；黑色牌，你获得当前回合角色一张牌。",

}











return extension
