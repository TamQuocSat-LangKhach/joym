local extension = Package("joy_re")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_re"] = "欢乐-RE",
}

--在原技能组上修改的武将
--群马超 魏庞德 张宝 何太后 孙鲁育 SP孙尚香 孙皓 麹义 神甄姬 张梁 群太史慈 吴庞统 周鲂 张昌蒲 唐姬 杜夫人 张嫙

local sunshangxiang = General(extension, "joysp__sunshangxiang", "shu", 3, 3, General.Female)
local joy__liangzhu = fk.CreateTriggerSkill{
  name = "joy__liangzhu",
  anim_type = "support",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Play
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
    return target == player and player:hasSkill(self.name) and
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

local godzhenji = General(extension, "joy__godzhenji", "god", 3, 3, General.Female)
local joy__shenfu = fk.CreateTriggerSkill{
  name = "joy__shenfu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    if player:getHandcardNum() % 2 == 1 then
      while true do
        local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
          return p.id end), 1, 1, "#shenfu-damage", self.name, true)
        if #tos > 0 then
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
        else
          break
        end
      end
    else
      while true do
        local tos = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
          return p:getMark("joy__shenfu-turn") == 0 end), function(p) return p.id end),
          1, 1, "#shenfu-hand", self.name, true)
        if #tos > 0 then
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
            if to:getHandcardNum() ~= to.hp then
              break
            end
          end
        else
          break
        end
      end
    end
    if not player.dead and n > 0 then
      player:drawCards(math.min(n, 5), self.name)
    end
  end,
}
local joy__qixian = fk.CreateMaxCardsSkill{
  name = "joy__qixian",
  fixed_func = function (self, player)
    if player:hasSkill(self.name) then
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
  ["joy__feifu"] = "飞凫",
  [":joy__feifu"] = "你可以将一张黑色牌当【闪】使用或打出。",
}

local tangji = General(extension, "joy__tangji", "qun", 3, 3, General.Female)
local joy__kangge = fk.CreateTriggerSkill{
  name = "joy__kangge",
  events = {fk.TurnStart, fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
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
    room:broadcastSkillInvoke(self.name)
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
    room:broadcastSkillInvoke("joy__kangge")
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
    return target == player and player:hasSkill(self.name)
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

return extension
