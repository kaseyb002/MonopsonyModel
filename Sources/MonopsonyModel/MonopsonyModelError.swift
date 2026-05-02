import Foundation

public enum MonopsonyModelError: Error, Equatable, Sendable {
    case notEnoughPlayers
    case tooManyPlayers
    case notWaitingForPlayerToAct
    case notInPreRollPhase
    case notInPostRollPhase
    case notInBuyDecisionPhase
    case notInAuctionPhase
    case notInBuildPhase
    case notInTradePhase
    case notInInvestigationPhase
    case playerNotFound
    case firmNotFound
    case firmAlreadyOwned
    case firmNotOwned
    case firmOwnedByAnotherPlayer
    case notEnoughCapital
    case cannotBuildWithoutIndustryControl
    case maxDepartmentsReached
    case mustBuildEvenly
    case cannotBuildOnFrozenFirm
    case firmNotFrozen
    case firmAlreadyFrozen
    case cannotFreezeWithDepartments
    case noSettlementAgreementAvailable
    case gameIsComplete
    case invalidAction
    case auctionInProgress
    case noBidders
}
