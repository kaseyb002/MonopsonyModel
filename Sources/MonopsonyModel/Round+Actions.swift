import Foundation

extension Round {
    // MARK: - Roll Dice

    public mutating func rollDice(cookedRoll: DiceRoll? = nil) throws {
        guard !isComplete else { throw MonopsonyModelError.gameIsComplete }
        guard case .preRoll(let playerID) = state else {
            throw MonopsonyModelError.notInPreRollPhase
        }
        guard let psIndex = playerStateIndex(for: playerID) else {
            throw MonopsonyModelError.playerNotFound
        }

        let roll: DiceRoll = cookedRoll ?? .random()
        lastDiceRoll = roll
        logAction(playerID: playerID, decision: .rolled(roll))

        // Handle investigation escape
        if playerStates[psIndex].isInInvestigation {
            handleInvestigationRoll(playerIndex: psIndex, roll: roll)
            return
        }

        // Check for three consecutive doubles → antitrust probe
        if roll.isDoubles {
            playerStates[psIndex].doublesRolledInRow += 1
            if playerStates[psIndex].doublesRolledInRow >= Self.maxDoublesBeforeProbe {
                sendToInvestigation(playerIndex: psIndex)
                playerStates[psIndex].doublesRolledInRow = 0
                advanceToNextPlayer()
                return
            }
        } else {
            playerStates[psIndex].doublesRolledInRow = 0
        }

        movePlayer(playerIndex: psIndex, spaces: roll.total)
        let landedSpace: BoardSpace = board.spaces[playerStates[psIndex].position]
        handleLanding(playerIndex: psIndex, space: landedSpace, diceRoll: roll)
    }

    // MARK: - Buy Firm

    public mutating func acquireFirm(playerID: PlayerID) throws {
        guard !isComplete else { throw MonopsonyModelError.gameIsComplete }
        guard case .buyDecision(let expectedID, let firmID) = state else {
            throw MonopsonyModelError.notInBuyDecisionPhase
        }
        guard playerID == expectedID else { throw MonopsonyModelError.notWaitingForPlayerToAct }
        guard let psIndex = playerStateIndex(for: playerID) else {
            throw MonopsonyModelError.playerNotFound
        }
        guard let firm = board.firm(byID: firmID) else {
            throw MonopsonyModelError.firmNotFound
        }
        guard playerStates[psIndex].player.capital >= firm.acquisitionCost else {
            throw MonopsonyModelError.notEnoughCapital
        }

        playerStates[psIndex].player.capital -= firm.acquisitionCost
        var updatedFirm: Firm = firm
        updatedFirm.controllingCompany = playerID
        board.updateFirm(updatedFirm)

        logAction(playerID: playerID, decision: .acquiredFirm(firmID: firmID, cost: firm.acquisitionCost))
        finishTurn(playerIndex: psIndex)
    }

    public mutating func declineFirm(playerID: PlayerID) throws {
        guard !isComplete else { throw MonopsonyModelError.gameIsComplete }
        guard case .buyDecision(let expectedID, let firmID) = state else {
            throw MonopsonyModelError.notInBuyDecisionPhase
        }
        guard playerID == expectedID else { throw MonopsonyModelError.notWaitingForPlayerToAct }
        guard let psIndex = playerStateIndex(for: playerID) else {
            throw MonopsonyModelError.playerNotFound
        }

        logAction(playerID: playerID, decision: .declinedFirm(firmID: firmID))
        finishTurn(playerIndex: psIndex)
    }

    // MARK: - Build Department

    public mutating func buildDepartment(playerID: PlayerID, firmID: FirmID) throws {
        guard !isComplete else { throw MonopsonyModelError.gameIsComplete }
        guard let psIndex = playerStateIndex(for: playerID) else {
            throw MonopsonyModelError.playerNotFound
        }
        guard var firm = board.firm(byID: firmID) else {
            throw MonopsonyModelError.firmNotFound
        }
        guard firm.controllingCompany == playerID else {
            throw MonopsonyModelError.firmNotOwned
        }
        guard !firm.isFrozen else {
            throw MonopsonyModelError.cannotBuildOnFrozenFirm
        }
        guard board.playerControlsIndustry(playerID, industry: firm.industry) else {
            throw MonopsonyModelError.cannotBuildWithoutIndustryControl
        }

        if firm.hasCampus {
            throw MonopsonyModelError.maxDepartmentsReached
        }

        if firm.departments >= Firm.maxDepartments {
            throw MonopsonyModelError.maxDepartmentsReached
        }

        // Even building rule: can't build on a firm if any other firm in the industry has fewer departments
        let industryFirms: [Firm] = board.firmsInIndustry(firm.industry)
        let minDepartments: Int = industryFirms.map(\.departments).min() ?? 0
        if firm.departments > minDepartments {
            throw MonopsonyModelError.mustBuildEvenly
        }

        guard playerStates[psIndex].player.capital >= firm.departmentCost else {
            throw MonopsonyModelError.notEnoughCapital
        }

        playerStates[psIndex].player.capital -= firm.departmentCost
        firm.departments += 1
        board.updateFirm(firm)

        logAction(playerID: playerID, decision: .builtDepartment(firmID: firmID, cost: firm.departmentCost))
    }

    // MARK: - Build Campus

    public mutating func buildCampus(playerID: PlayerID, firmID: FirmID) throws {
        guard !isComplete else { throw MonopsonyModelError.gameIsComplete }
        guard let psIndex = playerStateIndex(for: playerID) else {
            throw MonopsonyModelError.playerNotFound
        }
        guard var firm = board.firm(byID: firmID) else {
            throw MonopsonyModelError.firmNotFound
        }
        guard firm.controllingCompany == playerID else {
            throw MonopsonyModelError.firmNotOwned
        }
        guard !firm.isFrozen else {
            throw MonopsonyModelError.cannotBuildOnFrozenFirm
        }
        guard firm.departments == Firm.maxDepartments else {
            throw MonopsonyModelError.maxDepartmentsReached
        }
        guard !firm.hasCampus else {
            throw MonopsonyModelError.maxDepartmentsReached
        }
        guard board.playerControlsIndustry(playerID, industry: firm.industry) else {
            throw MonopsonyModelError.cannotBuildWithoutIndustryControl
        }

        // Even building rule for campus: all firms in industry must have 4 departments
        let industryFirms: [Firm] = board.firmsInIndustry(firm.industry)
        let allMaxed: Bool = industryFirms.allSatisfy { $0.departments == Firm.maxDepartments }
        guard allMaxed else {
            throw MonopsonyModelError.mustBuildEvenly
        }

        guard playerStates[psIndex].player.capital >= firm.campusCost else {
            throw MonopsonyModelError.notEnoughCapital
        }

        playerStates[psIndex].player.capital -= firm.campusCost
        firm.hasCampus = true
        firm.departments = 0
        board.updateFirm(firm)

        logAction(playerID: playerID, decision: .builtCampus(firmID: firmID, cost: firm.campusCost))
    }

    // MARK: - Freeze Hiring (Mortgage)

    public mutating func freezeHiring(playerID: PlayerID, firmID: FirmID) throws {
        guard !isComplete else { throw MonopsonyModelError.gameIsComplete }
        guard let psIndex = playerStateIndex(for: playerID) else {
            throw MonopsonyModelError.playerNotFound
        }
        guard var firm = board.firm(byID: firmID) else {
            throw MonopsonyModelError.firmNotFound
        }
        guard firm.controllingCompany == playerID else {
            throw MonopsonyModelError.firmNotOwned
        }
        guard !firm.isFrozen else {
            throw MonopsonyModelError.firmAlreadyFrozen
        }
        guard firm.departments == 0 && !firm.hasCampus else {
            throw MonopsonyModelError.cannotFreezeWithDepartments
        }

        firm.isFrozen = true
        board.updateFirm(firm)
        playerStates[psIndex].player.capital += firm.frozenValue

        logAction(playerID: playerID, decision: .frozeHiring(firmID: firmID, received: firm.frozenValue))
    }

    // MARK: - Resume Hiring (Unmortgage)

    public mutating func resumeHiring(playerID: PlayerID, firmID: FirmID) throws {
        guard !isComplete else { throw MonopsonyModelError.gameIsComplete }
        guard let psIndex = playerStateIndex(for: playerID) else {
            throw MonopsonyModelError.playerNotFound
        }
        guard var firm = board.firm(byID: firmID) else {
            throw MonopsonyModelError.firmNotFound
        }
        guard firm.controllingCompany == playerID else {
            throw MonopsonyModelError.firmNotOwned
        }
        guard firm.isFrozen else {
            throw MonopsonyModelError.firmNotFrozen
        }

        let cost: Int = firm.frozenValue + firm.unfreezeExtra
        guard playerStates[psIndex].player.capital >= cost else {
            throw MonopsonyModelError.notEnoughCapital
        }

        firm.isFrozen = false
        board.updateFirm(firm)
        playerStates[psIndex].player.capital -= cost

        logAction(playerID: playerID, decision: .resumedHiring(firmID: firmID, cost: cost))
    }

    // MARK: - Pay Bail (Investigation)

    public mutating func payBail(playerID: PlayerID) throws {
        guard !isComplete else { throw MonopsonyModelError.gameIsComplete }
        guard case .preRoll(let expectedID) = state else {
            throw MonopsonyModelError.notInPreRollPhase
        }
        guard playerID == expectedID else { throw MonopsonyModelError.notWaitingForPlayerToAct }
        guard let psIndex = playerStateIndex(for: playerID) else {
            throw MonopsonyModelError.playerNotFound
        }
        guard playerStates[psIndex].isInInvestigation else {
            throw MonopsonyModelError.notInInvestigationPhase
        }
        guard playerStates[psIndex].player.capital >= Self.investigationBailCost else {
            throw MonopsonyModelError.notEnoughCapital
        }

        playerStates[psIndex].player.capital -= Self.investigationBailCost
        playerStates[psIndex].isInInvestigation = false
        playerStates[psIndex].turnsInInvestigation = 0

        logAction(playerID: playerID, decision: .escapedInvestigation(method: .paidBail))
        state = .preRoll(playerID: playerID)
    }

    // MARK: - Use Settlement Agreement

    public mutating func useSettlementAgreement(playerID: PlayerID) throws {
        guard !isComplete else { throw MonopsonyModelError.gameIsComplete }
        guard case .preRoll(let expectedID) = state else {
            throw MonopsonyModelError.notInPreRollPhase
        }
        guard playerID == expectedID else { throw MonopsonyModelError.notWaitingForPlayerToAct }
        guard let psIndex = playerStateIndex(for: playerID) else {
            throw MonopsonyModelError.playerNotFound
        }
        guard playerStates[psIndex].isInInvestigation else {
            throw MonopsonyModelError.notInInvestigationPhase
        }
        guard playerStates[psIndex].settlementAgreements > 0 else {
            throw MonopsonyModelError.noSettlementAgreementAvailable
        }

        playerStates[psIndex].settlementAgreements -= 1
        playerStates[psIndex].isInInvestigation = false
        playerStates[psIndex].turnsInInvestigation = 0

        logAction(playerID: playerID, decision: .escapedInvestigation(method: .usedSettlement))
        state = .preRoll(playerID: playerID)
    }

    // MARK: - End Turn

    public mutating func endTurn(playerID: PlayerID) throws {
        guard !isComplete else { throw MonopsonyModelError.gameIsComplete }
        guard let psIndex = playerStateIndex(for: playerID) else {
            throw MonopsonyModelError.playerNotFound
        }

        switch state {
        case .awaitingAction(let expectedID):
            guard playerID == expectedID else { throw MonopsonyModelError.notWaitingForPlayerToAct }
        case .buyDecision(let expectedID, let firmID):
            guard playerID == expectedID else { throw MonopsonyModelError.notWaitingForPlayerToAct }
            logAction(playerID: playerID, decision: .declinedFirm(firmID: firmID))
        default:
            throw MonopsonyModelError.notWaitingForPlayerToAct
        }

        logAction(playerID: playerID, decision: .passedTurn)
        finishTurn(playerIndex: psIndex)
    }

    // MARK: - Private: Movement

    mutating func movePlayer(playerIndex: Int, spaces: Int) {
        let oldPosition: Int = playerStates[playerIndex].position
        let newPosition: Int = (oldPosition + spaces) % board.spaceCount
        let passedPayroll: Bool = (oldPosition + spaces) >= board.spaceCount && spaces > 0

        if passedPayroll {
            playerStates[playerIndex].player.capital += Self.payrollSalary
            logAction(
                playerID: playerStates[playerIndex].player.id,
                decision: .collectedPayroll(amount: Self.payrollSalary)
            )
        }

        playerStates[playerIndex].position = newPosition
    }

    mutating func movePlayerTo(playerIndex: Int, spaceIndex: Int, collectPayroll: Bool) {
        let oldPosition: Int = playerStates[playerIndex].position
        if collectPayroll && spaceIndex <= oldPosition && spaceIndex != oldPosition {
            playerStates[playerIndex].player.capital += Self.payrollSalary
            logAction(
                playerID: playerStates[playerIndex].player.id,
                decision: .collectedPayroll(amount: Self.payrollSalary)
            )
        }
        playerStates[playerIndex].position = spaceIndex
    }

    // MARK: - Private: Landing

    mutating func handleLanding(playerIndex: Int, space: BoardSpace, diceRoll: DiceRoll) {
        let playerID: PlayerID = playerStates[playerIndex].player.id

        switch space {
        case .payroll:
            finishTurn(playerIndex: playerIndex)

        case .firm(let firmID):
            handleFirmLanding(playerIndex: playerIndex, firmID: firmID)

        case .staffingAgency(let firmID):
            handleStaffingAgencyLanding(playerIndex: playerIndex, firmID: firmID, diceRoll: diceRoll)

        case .laborPlatform(let firmID):
            handleLaborPlatformLanding(playerIndex: playerIndex, firmID: firmID, diceRoll: diceRoll)

        case .payrollTax:
            let tax: Int = min(Self.payrollTaxAmount, playerStates[playerIndex].player.capital)
            playerStates[playerIndex].player.capital -= tax
            logAction(playerID: playerID, decision: .paidPayrollTax(amount: tax))
            checkBankruptcy(playerIndex: playerIndex)
            finishTurn(playerIndex: playerIndex)

        case .complianceFine:
            let fine: Int = min(Self.complianceFineAmount, playerStates[playerIndex].player.capital)
            playerStates[playerIndex].player.capital -= fine
            logAction(playerID: playerID, decision: .paidComplianceFine(amount: fine))
            checkBankruptcy(playerIndex: playerIndex)
            finishTurn(playerIndex: playerIndex)

        case .marketShock:
            handleMarketShockCard(playerIndex: playerIndex, diceRoll: diceRoll)

        case .laborBoard:
            handleLaborBoardCard(playerIndex: playerIndex, diceRoll: diceRoll)

        case .antitrustProbe:
            sendToInvestigation(playerIndex: playerIndex)
            advanceToNextPlayer()

        case .underObservation:
            finishTurn(playerIndex: playerIndex)

        case .publicGrant:
            if publicGrantPool > 0 {
                playerStates[playerIndex].player.capital += publicGrantPool
                publicGrantPool = 0
            }
            finishTurn(playerIndex: playerIndex)
        }
    }

    // MARK: - Private: Firm Landing

    private mutating func handleFirmLanding(playerIndex: Int, firmID: FirmID) {
        let playerID: PlayerID = playerStates[playerIndex].player.id
        guard let firm = board.firm(byID: firmID) else {
            finishTurn(playerIndex: playerIndex)
            return
        }

        if let owner = firm.controllingCompany {
            if owner == playerID || firm.isFrozen {
                finishTurn(playerIndex: playerIndex)
            } else {
                let premium: Int = firm.currentWagePremium
                let actualPayment: Int = min(premium, playerStates[playerIndex].player.capital)
                playerStates[playerIndex].player.capital -= actualPayment
                if let ownerIndex = playerStateIndex(for: owner) {
                    playerStates[ownerIndex].player.capital += actualPayment
                }
                logAction(playerID: playerID, decision: .paidWagePremium(firmID: firmID, toPlayer: owner, amount: actualPayment))
                checkBankruptcy(playerIndex: playerIndex)
                finishTurn(playerIndex: playerIndex)
            }
        } else {
            if playerStates[playerIndex].player.capital >= firm.acquisitionCost {
                state = .buyDecision(playerID: playerID, firmID: firmID)
            } else {
                finishTurn(playerIndex: playerIndex)
            }
        }
    }

    private mutating func handleStaffingAgencyLanding(playerIndex: Int, firmID: FirmID, diceRoll: DiceRoll) {
        let playerID: PlayerID = playerStates[playerIndex].player.id
        guard let firm = board.firm(byID: firmID) else {
            finishTurn(playerIndex: playerIndex)
            return
        }

        if let owner = firm.controllingCompany {
            if owner == playerID || firm.isFrozen {
                finishTurn(playerIndex: playerIndex)
            } else {
                let ownedCount: Int = board.staffingAgencyCount(for: owner)
                let premium: Int = board.staffingAgencyWagePremium(ownedCount: ownedCount)
                let actualPayment: Int = min(premium, playerStates[playerIndex].player.capital)
                playerStates[playerIndex].player.capital -= actualPayment
                if let ownerIndex = playerStateIndex(for: owner) {
                    playerStates[ownerIndex].player.capital += actualPayment
                }
                logAction(playerID: playerID, decision: .paidWagePremium(firmID: firmID, toPlayer: owner, amount: actualPayment))
                checkBankruptcy(playerIndex: playerIndex)
                finishTurn(playerIndex: playerIndex)
            }
        } else {
            if playerStates[playerIndex].player.capital >= firm.acquisitionCost {
                state = .buyDecision(playerID: playerID, firmID: firmID)
            } else {
                finishTurn(playerIndex: playerIndex)
            }
        }
    }

    private mutating func handleLaborPlatformLanding(playerIndex: Int, firmID: FirmID, diceRoll: DiceRoll) {
        let playerID: PlayerID = playerStates[playerIndex].player.id
        guard let firm = board.firm(byID: firmID) else {
            finishTurn(playerIndex: playerIndex)
            return
        }

        if let owner = firm.controllingCompany {
            if owner == playerID || firm.isFrozen {
                finishTurn(playerIndex: playerIndex)
            } else {
                let ownedCount: Int = board.laborPlatformCount(for: owner)
                let premium: Int = board.laborPlatformWagePremium(ownedCount: ownedCount, diceRoll: diceRoll.total)
                let actualPayment: Int = min(premium, playerStates[playerIndex].player.capital)
                playerStates[playerIndex].player.capital -= actualPayment
                if let ownerIndex = playerStateIndex(for: owner) {
                    playerStates[ownerIndex].player.capital += actualPayment
                }
                logAction(playerID: playerID, decision: .paidWagePremium(firmID: firmID, toPlayer: owner, amount: actualPayment))
                checkBankruptcy(playerIndex: playerIndex)
                finishTurn(playerIndex: playerIndex)
            }
        } else {
            if playerStates[playerIndex].player.capital >= firm.acquisitionCost {
                state = .buyDecision(playerID: playerID, firmID: firmID)
            } else {
                finishTurn(playerIndex: playerIndex)
            }
        }
    }

    // MARK: - Private: Card Effects

    private mutating func handleMarketShockCard(playerIndex: Int, diceRoll: DiceRoll) {
        let playerID: PlayerID = playerStates[playerIndex].player.id
        guard let card = board.drawMarketShock() else {
            finishTurn(playerIndex: playerIndex)
            return
        }

        logAction(playerID: playerID, decision: .drewMarketShock(title: card.title))
        applyCardEffect(card.effect, playerIndex: playerIndex, diceRoll: diceRoll)

        if case .settlementAgreement = card.effect {
            playerStates[playerIndex].settlementAgreements += 1
        } else {
            board.discardMarketShock(card)
        }
    }

    private mutating func handleLaborBoardCard(playerIndex: Int, diceRoll: DiceRoll) {
        let playerID: PlayerID = playerStates[playerIndex].player.id
        guard let card = board.drawLaborBoard() else {
            finishTurn(playerIndex: playerIndex)
            return
        }

        logAction(playerID: playerID, decision: .drewLaborBoard(title: card.title))
        applyCardEffect(card.effect, playerIndex: playerIndex, diceRoll: diceRoll)

        if case .settlementAgreement = card.effect {
            playerStates[playerIndex].settlementAgreements += 1
        } else {
            board.discardLaborBoard(card)
        }
    }

    private mutating func applyCardEffect(_ effect: CardEffect, playerIndex: Int, diceRoll: DiceRoll) {
        let playerID: PlayerID = playerStates[playerIndex].player.id

        switch effect {
        case .gainCapital(let amount):
            playerStates[playerIndex].player.capital += amount
            finishTurn(playerIndex: playerIndex)

        case .loseCapital(let amount):
            let loss: Int = min(amount, playerStates[playerIndex].player.capital)
            playerStates[playerIndex].player.capital -= loss
            publicGrantPool += loss
            checkBankruptcy(playerIndex: playerIndex)
            finishTurn(playerIndex: playerIndex)

        case .moveToSpace(let spaceIndex):
            movePlayerTo(playerIndex: playerIndex, spaceIndex: spaceIndex, collectPayroll: true)
            let space: BoardSpace = board.spaces[playerStates[playerIndex].position]
            handleLanding(playerIndex: playerIndex, space: space, diceRoll: diceRoll)

        case .moveSpaces(let count):
            let newPos: Int = (playerStates[playerIndex].position + count + board.spaceCount) % board.spaceCount
            playerStates[playerIndex].position = newPos
            let space: BoardSpace = board.spaces[newPos]
            handleLanding(playerIndex: playerIndex, space: space, diceRoll: diceRoll)

        case .antitrustProbe:
            sendToInvestigation(playerIndex: playerIndex)
            advanceToNextPlayer()

        case .settlementAgreement:
            finishTurn(playerIndex: playerIndex)

        case .payEachPlayer(let amount):
            let activePlayers: [Int] = playerStates.indices.filter {
                $0 != playerIndex && !playerStates[$0].isBankrupt
            }
            for otherIndex in activePlayers {
                let payment: Int = min(amount, playerStates[playerIndex].player.capital)
                playerStates[playerIndex].player.capital -= payment
                playerStates[otherIndex].player.capital += payment
            }
            checkBankruptcy(playerIndex: playerIndex)
            finishTurn(playerIndex: playerIndex)

        case .collectFromEachPlayer(let amount):
            let activePlayers: [Int] = playerStates.indices.filter {
                $0 != playerIndex && !playerStates[$0].isBankrupt
            }
            for otherIndex in activePlayers {
                let payment: Int = min(amount, playerStates[otherIndex].player.capital)
                playerStates[otherIndex].player.capital -= payment
                playerStates[playerIndex].player.capital += payment
            }
            finishTurn(playerIndex: playerIndex)

        case .repairCost(let perDepartment, let perCampus):
            var totalCost: Int = 0
            for firm in board.firms where firm.controllingCompany == playerID {
                totalCost += firm.departments * perDepartment
                if firm.hasCampus { totalCost += perCampus }
            }
            let loss: Int = min(totalCost, playerStates[playerIndex].player.capital)
            playerStates[playerIndex].player.capital -= loss
            publicGrantPool += loss
            checkBankruptcy(playerIndex: playerIndex)
            finishTurn(playerIndex: playerIndex)
        }
    }

    // MARK: - Private: Investigation

    private mutating func handleInvestigationRoll(playerIndex: Int, roll: DiceRoll) {
        let playerID: PlayerID = playerStates[playerIndex].player.id

        playerStates[playerIndex].turnsInInvestigation += 1

        if roll.isDoubles {
            playerStates[playerIndex].isInInvestigation = false
            playerStates[playerIndex].turnsInInvestigation = 0
            playerStates[playerIndex].doublesRolledInRow = 0
            logAction(playerID: playerID, decision: .escapedInvestigation(method: .rolledDoubles))
            movePlayer(playerIndex: playerIndex, spaces: roll.total)
            let space: BoardSpace = board.spaces[playerStates[playerIndex].position]
            handleLanding(playerIndex: playerIndex, space: space, diceRoll: roll)
            return
        }

        if playerStates[playerIndex].turnsInInvestigation >= Self.maxTurnsInInvestigation {
            playerStates[playerIndex].player.capital -= min(Self.investigationBailCost, playerStates[playerIndex].player.capital)
            playerStates[playerIndex].isInInvestigation = false
            playerStates[playerIndex].turnsInInvestigation = 0
            logAction(playerID: playerID, decision: .escapedInvestigation(method: .paidBail))
            checkBankruptcy(playerIndex: playerIndex)
            advanceToNextPlayer()
            return
        }

        advanceToNextPlayer()
    }

    mutating func sendToInvestigation(playerIndex: Int) {
        let investigationSpaceIndex: Int = 10
        playerStates[playerIndex].position = investigationSpaceIndex
        playerStates[playerIndex].isInInvestigation = true
        playerStates[playerIndex].turnsInInvestigation = 0
        playerStates[playerIndex].doublesRolledInRow = 0
        logAction(playerID: playerStates[playerIndex].player.id, decision: .sentToInvestigation)
    }

    // MARK: - Private: Turn Management

    mutating func finishTurn(playerIndex: Int) {
        guard !playerStates[playerIndex].isBankrupt else {
            advanceToNextPlayer()
            return
        }

        if let roll = lastDiceRoll, roll.isDoubles, !playerStates[playerIndex].isInInvestigation {
            state = .preRoll(playerID: playerStates[playerIndex].player.id)
            return
        }

        advanceToNextPlayer()
    }

    mutating func advanceToNextPlayer() {
        let activePlayers: [Int] = playerStates.indices.filter { !playerStates[$0].isBankrupt }

        if activePlayers.count <= 1 {
            endGame()
            return
        }

        var nextIndex: Int = (currentPlayerIndex + 1) % playerStates.count
        while playerStates[nextIndex].isBankrupt {
            nextIndex = (nextIndex + 1) % playerStates.count
        }
        currentPlayerIndex = nextIndex
        lastDiceRoll = nil
        state = .preRoll(playerID: playerStates[nextIndex].player.id)
    }

    mutating func checkBankruptcy(playerIndex: Int) {
        if playerStates[playerIndex].player.capital <= 0 {
            playerStates[playerIndex].isBankrupt = true
            logAction(playerID: playerStates[playerIndex].player.id, decision: .wentBankrupt)

            // Return all firms
            for i in board.firms.indices {
                if board.firms[i].controllingCompany == playerStates[playerIndex].player.id {
                    board.firms[i].controllingCompany = nil
                    board.firms[i].departments = 0
                    board.firms[i].hasCampus = false
                    board.firms[i].isFrozen = false
                }
            }
        }
    }

    private mutating func endGame() {
        let activePlayers: [PlayerState] = playerStates.filter { !$0.isBankrupt }

        guard let winner = activePlayers.max(by: { a, b in
            totalAssetValue(for: a) < totalAssetValue(for: b)
        }) else { return }

        ended = .now
        state = .gameComplete(winner: winner.player)
    }

    // MARK: - Private: Logging

    mutating func logAction(playerID: PlayerID, decision: Action.Decision) {
        log.append(Action(playerID: playerID, decision: decision, timestamp: .now))
        if log.count > Self.maxLogActions {
            log.removeFirst(log.count - Self.maxLogActions)
        }
    }
}
