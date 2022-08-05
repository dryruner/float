// MADE BY: Bohao Tang

// This contract is for FLOAT Events Book

import NonFungibleToken from "../core-contracts/NonFungibleToken.cdc"
import MetadataViews from "../core-contracts/MetadataViews.cdc"
import FungibleToken from "../core-contracts/FungibleToken.cdc"
import FLOAT from "../float/FLOAT.cdc"

pub contract FLOATEventSeries {

    /**    ___  ____ ___ _  _ ____
       *   |__] |__|  |  |__| [__
        *  |    |  |  |  |  | ___]
         *************************/
    
    pub let FLOATEventSeriesGlobalStoragePath: StoragePath
    pub let FLOATEventSeriesGlobalPublicPath: PublicPath

    pub let FLOATEventSeriesBuilderStoragePath: StoragePath
    pub let FLOATEventSeriesBuilderPrivatePath: PrivatePath
    pub let FLOATEventSeriesBuilderPublicPath: PublicPath

    pub let FLOATAchievementBoardStoragePath: StoragePath
    pub let FLOATAchievementBoardPublicPath: PublicPath

    /**    ____ _  _ ____ _  _ ___ ____
       *   |___ |  | |___ |\ |  |  [__
        *  |___  \/  |___ | \|  |  ___]
         ******************************/
    
    pub event ContractInitialized()
    pub event ContractTokenDefintionUpdated(identifier: String, path: PublicPath, isNFT: Bool)

    pub event FLOATEventSeriesCreated(seriesId: UInt64, host: Address, name: String, description: String, image: String)
    pub event FLOATEventSeriesRevoked(seriesId: UInt64, host: Address)
    pub event FLOATEventSeriesRecovered(seriesId: UInt64, host: Address)
    pub event FLOATEventSeriesBasicsUpdated(seriesId: UInt64, host: Address, name: String, description: String, image: String)
    pub event FLOATEventSeriesSlotUpdated(seriesId: UInt64, host: Address, index: Int, eventHost: Address, eventId: UInt64)
    pub event FLOATEventSeriesGoalAdded(seriesId: UInt64, host: Address, goalTitle: String, points: UInt64)

    pub event FLOATEventSeriesTreasuryTokenDeposit(seriesId: UInt64, host: Address, identifier: String, amount: UFix64)
    pub event FLOATEventSeriesTreasuryTokenWithdraw(seriesId: UInt64, host: Address, identifier: String, amount: UFix64)
    pub event FLOATEventSeriesTreasuryNFTDeposit(seriesId: UInt64, host: Address, identifier: String, ids: [UInt64])
    pub event FLOATEventSeriesTreasuryNFTWithdraw(seriesId: UInt64, host: Address, identifier: String, ids: [UInt64])
    pub event FLOATEventSeriesTreasuryUpdateDropReceiver(seriesId: UInt64, host: Address, receiver: Address)
    pub event FLOATEventSeriesTreasuryDropped(seriesId: UInt64, host: Address?, receiver: Address)
    pub event FLOATEventSeriesTreasuryStrategyAdded(seriesId: UInt64, host: Address, strategyIdentifier: String, index: Int)
    pub event FLOATEventSeriesTreasuryStrategyNextStage(seriesId: UInt64, host: Address, strategyIdentifier: String, index: Int, stage: UInt8)
    pub event FLOATEventSeriesTreasuryClaimed(seriesId: UInt64, host: Address, strategyIdentifier: String, index: Int, claimer: Address)

    pub event FLOATEventSeriesGlobalAddedToList(seriesId: UInt64, host: Address)
    pub event FLOATEventSeriesGlobalTreasuryStrategyUpdated(seriesId: UInt64, host: Address)

    pub event FLOATEventSeriesBuilderCreated(sequence: UInt64)

    pub event FLOATAchievementRecordInitialized(seriesId: UInt64, host: Address, owner: Address)
    pub event FLOATAchievementGoalAccomplished(seriesId: UInt64, host: Address, owner: Address, goalIdx: Int)

    pub event FLOATAchievementBoardCreated(sequence: UInt64)

    /**    ____ ___ ____ ___ ____
       *   [__   |  |__|  |  |___
        *  ___]  |  |  |  |  |___
         ************************/
    
    // total event series amount
    pub var totalEventSeries: UInt64
    // total event series builder amount
    pub var totalEventSeriesBuilder: UInt64
    // total achievement board amount
    pub var totalAchievementBoards: UInt64

    // a registory of FT or NFT
    access(account) var tokenDefinitions: {Type: TokenDefinition}

    /**    ____ _  _ _  _ ____ ___ _ ____ _  _ ____ _    _ ___ _   _
       *   |___ |  | |\ | |     |  | |  | |\ | |__| |    |  |   \_/
        *  |    |__| | \| |___  |  | |__| | \| |  | |___ |  |    |
         ***********************************************************/

    // the Token define struct of FT or NFT
    pub struct TokenDefinition {
        pub let type: Type
        pub let path: PublicPath
        pub let isNFT: Bool

        init(type: Type, path: PublicPath, isNFT: Bool) {
            self.type = type
            self.path = path
            self.isNFT = isNFT
        }
    }

    access(account) fun setTokenDefintion(token: Type, path: PublicPath, isNFT: Bool) {
        self.tokenDefinitions[token] = TokenDefinition(
            type: token,
            path: path,
            isNFT: isNFT
        )
        emit ContractTokenDefintionUpdated(identifier: token.identifier, path: path, isNFT: isNFT)
    }

    pub fun getTokenDefinition(_ token: Type): TokenDefinition? {
        return self.tokenDefinitions[token]
    }

    // a helper to get token recipient
    pub struct TokenRecipient {
        pub let address: Address
        pub let identifier: Type

        init(_ address: Address, _ identifier: Type) {
            self.address = address
            self.identifier = identifier
        }

        // check if the token is NFT
        access(contract) fun isNFT(): Bool {
            let tokenInfo = FLOATEventSeries.getTokenDefinition(self.identifier) ?? panic("Unknown token")
            return tokenInfo.isNFT
        }

        // get ft receiver by address and identifier
        access(contract) fun getFungibleTokenReceiver(): &{FungibleToken.Receiver} {
            let tokenInfo = FLOATEventSeries.getTokenDefinition(self.identifier) ?? panic("Unknown token")
            assert(!tokenInfo.isNFT, message: "The token should be Fungiable Token")

            let receiverVault = getAccount(self.address)
                .getCapability(tokenInfo.path)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow the &{FungibleToken.Receiver} from ".concat(self.address.toString()))

            assert(
                receiverVault.getType() == tokenInfo.type,
                message: "The receiver's path is not associated with the intended token."
            )
            return receiverVault
        }

        // get nft collection by address and identifier
        access(contract) fun getNFTCollectionPublic(): &{NonFungibleToken.CollectionPublic} {
            let tokenInfo = FLOATEventSeries.getTokenDefinition(self.identifier) ?? panic("Unknown token")
            assert(tokenInfo.isNFT, message: "The token should be Non-Fungiable Token")

            let collection = getAccount(self.address)
                .getCapability(tokenInfo.path)
                .borrow<&{NonFungibleToken.CollectionPublic}>()
                ?? panic("Could not borrow the &{NonFungibleToken.CollectionPublic} from ".concat(self.address.toString()))
            // currently there is no generic collection
            assert(
                collection.getType().identifier.slice(from: 0, upTo: 18) == tokenInfo.type.identifier.slice(from: 0, upTo: 18),
                message: "The collection's path is not associated with the nft."
            )
            return collection
        }
    }

    // ---- data For Curators ----
    
    // identifier of an Event
    pub struct EventIdentifier {
        // event owner address
        pub let host: Address
        // event id
        pub let id: UInt64

        init(_ address: Address, _ id: UInt64) {
            self.host = address
            self.id = id
        }

        // get the reference of the given event
        pub fun getEventPublic(): &FLOAT.FLOATEvent{FLOAT.FLOATEventPublic} {
            let ownerEvents = getAccount(self.host)
                .getCapability(FLOAT.FLOATEventsPublicPath)
                .borrow<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic}>()
                ?? panic("Could not borrow the public FLOATEvents.")
            return ownerEvents.borrowPublicEventRef(eventId: self.id)
                ?? panic("Failed to get event reference.")
        }

        // convert identifier to string
        pub fun toString(): String {
            return self.host.toString().concat("#").concat(self.id.toString())
        }
    }

    // identifier of a EventSeries
    pub struct EventSeriesIdentifier {
        // series owner address
        pub let host: Address
        // series id
        pub let id: UInt64

        init(_ address: Address, _ id: UInt64) {
            self.host = address
            self.id = id
        }

        // get the reference of the given series
        pub fun getEventSeriesPublic(): &{EventSeriesPublic} {
            let ref = getAccount(self.host)
                .getCapability(FLOATEventSeries.FLOATEventSeriesBuilderPublicPath)
                .borrow<&EventSeriesBuilder{EventSeriesBuilderPublic}>()
                ?? panic("Could not borrow the public EventSeriesBuilderPublic.")
            return ref.borrowEventSeries(seriesId: self.id)
                ?? panic("Failed to get event series reference.")
        }

        // convert identifier to string
        pub fun toString(): String {
            return self.host.toString().concat("#").concat(self.id.toString())
        }
    }

    // a readable interface of Event slot
    pub struct interface EventSlot {
        // get the event identifier
        pub fun getIdentifier(): EventIdentifier?
        // if the event is required for achievement
        pub fun isEventRequired(): Bool
        // set the event identifier
        access(account) fun setIdentifier (_ identifier: EventIdentifier)
    }

    // set a required event slot of some specific event
    pub struct RequiredEventSlot: EventSlot {
        pub let identifier: EventIdentifier

        init(_ identifier: EventIdentifier) {
            self.identifier = identifier
        }

        pub fun getIdentifier(): EventIdentifier? {
            return self.identifier
        }

        pub fun isEventRequired(): Bool {
            return true
        }

        access(account) fun setIdentifier (_ identifier: EventIdentifier) {
            panic("cannot setIdentifier for RequiredEventSlot.")
        }
    }
    
    // set an optional event slot of some specific event
    pub struct OptionalEventSlot: EventSlot {
        pub var identifier: EventIdentifier?

        init(_ identifier: EventIdentifier?) {
            self.identifier = identifier
        }
        pub fun getIdentifier(): EventIdentifier? {
            return self.identifier
        }
        pub fun isEventRequired(): Bool {
            return false
        }
        access(account) fun setIdentifier (_ identifier: EventIdentifier) {
            self.identifier = identifier
        }
    }

    // set an event slot for unknown events
    pub struct EmptyEventSlot: EventSlot {
        pub let isRequired: Bool
        pub var identifier: EventIdentifier?

        init(_ isRequired: Bool) {
            self.isRequired = isRequired
            self.identifier = nil
        }
        pub fun getIdentifier(): EventIdentifier? {
            return self.identifier
        }
        pub fun isEventRequired(): Bool {
            return self.isRequired
        }
        access(account) fun setIdentifier (_ identifier: EventIdentifier) {
            self.identifier = identifier
        }
    }

    // An interface that every "achievement goal" must implement
    pub struct interface IAchievementGoal {
        // achievement title
        pub let title: String

        // how many points will be obtain when reach this goal
        pub fun getPoints(): UInt64 {
            post {
                result > 0: "Point should be greater than zero."
            }
        }

        // Fetch detail of the goal
        pub fun getGoalDetail(): {String: AnyStruct}

        // Check if user fits some criteria.
        access(account) fun verify(_ eventSeries: &{EventSeriesPublic}, user: Address): Bool
    }

    // Declare an enum to describe status
    pub enum StrategyState: UInt8 {
        pub case preparing
        pub case opening
        pub case claimable
        pub case closed
    }

    pub enum StrategyDeliveryType: UInt8 {
        pub case ftIdenticalAmount
        pub case ftRandomAmount
        pub case nft
    }

    // delivery information
    pub struct interface StrategyDelivery {
        // which delivery type
        pub let type: StrategyDeliveryType
        // is delivery nft?
        pub let isNFT: Bool
        // which token is this strategy to deliver
        pub let deliveryTokenType: Type
        // how many claimable shares
        pub let maxClaimableShares: UInt64
        // how many shares has been delivered
        pub var claimedShares: UInt64
        // ---- readonly methods ----
        // get total amount (For FT) of the delivery
        pub fun getTotalAmount(): UFix64
        // get rest amount (For FT) of the delivery
        pub fun getRestAmount(): UFix64
        // ---- writable methods ----
        access(contract) fun deliverFT(treasury: &Treasury, recipient: &{FungibleToken.Receiver}): UFix64 {
            pre {
                !self.isNFT: "Strategy should be delivering Fungible Token"
                self.claimedShares < self.maxClaimableShares: "no more than max claimable."
            }
            post {
                self.claimedShares == before(self.claimedShares) + 1: "ensure one share delivered"
            }
        }
        access(contract) fun deliverNFT(treasury: &Treasury, recipient: &{NonFungibleToken.CollectionPublic}): [UInt64] {
            pre {
                self.isNFT: "Strategy should be delivering NFT"
                self.claimedShares < self.maxClaimableShares: "no more than max claimable."
            }
            post {
                self.claimedShares == before(self.claimedShares) + 1: "ensure one share delivered"
            }
        }
    }

    // StrategyDeliveryType.ftIdenticalAmount
    pub struct StrategyDeliveryFTWithIdenticalAmount: StrategyDelivery {
        // interface implement
        pub let type: StrategyDeliveryType
        pub let isNFT: Bool
        pub let deliveryTokenType: Type
        pub let maxClaimableShares: UInt64
        pub var claimedShares: UInt64
        // local implement
        pub let oneShareAmount: UFix64
        pub var restAmount: UFix64

        init(
            _ tokenType: Type,
            _ maxClaimableShares: UInt64,
            oneShareAmount: UFix64,
        ) {
            self.type = StrategyDeliveryType.ftIdenticalAmount
            self.isNFT = false
            self.deliveryTokenType = tokenType
            self.maxClaimableShares = maxClaimableShares
            self.claimedShares = 0
            self.oneShareAmount = oneShareAmount
            self.restAmount = self.getTotalAmount()
        }
        // interface implement
        pub fun getTotalAmount(): UFix64 {
            return self.oneShareAmount.saturatingMultiply(UFix64(self.maxClaimableShares))
        }
        pub fun getRestAmount(): UFix64 {
            return self.restAmount
        }

        // ---- writable methods ----
        access(contract) fun deliverFT(treasury: &Treasury, recipient: &{FungibleToken.Receiver}): UFix64 {
            pre {
                self.restAmount >= self.oneShareAmount: "rest amount is not enough."
            }
            post {
                self.restAmount >= 0.0: "rest amount should be greator then zero."
            }
            // ensure enough
            treasury.ensureFTEnough(type: self.deliveryTokenType, amount: self.oneShareAmount)
            // ensure type is same
            assert(recipient.getType() == self.deliveryTokenType, message: "Recipient identifier should be same as definition")
            let treasuryRef = &treasury.genericFTPool[self.deliveryTokenType] as &{FungibleToken.Provider, FungibleToken.Balance}?

            // do 'transfer' action
            let ft <- treasuryRef!.withdraw(amount: self.oneShareAmount)
            // reduce the restAmount
            self.restAmount = self.restAmount - ft.balance
            recipient.deposit(from: <- ft)

            // add one to claimed
            self.claimedShares = self.claimedShares + 1

            return self.oneShareAmount
        }
        access(contract) fun deliverNFT(treasury: &Treasury, recipient: &{NonFungibleToken.CollectionPublic}): [UInt64] {
            panic("This strategy without NFT delivery method")
        }
    }

    // StrategyDeliveryType.ftRandomAmount
    pub struct StrategyDeliveryFTWithRandomAmount: StrategyDelivery {
        // interface implement
        pub let type: StrategyDeliveryType
        pub let isNFT: Bool
        pub let deliveryTokenType: Type
        pub let maxClaimableShares: UInt64
        pub var claimedShares: UInt64
        // local implement
        pub let totalAmount: UFix64
        pub var restAmount: UFix64

        init(
            _ tokenType: Type,
            _ maxClaimableShares: UInt64,
            totalAmount: UFix64,
        ) {
            self.type = StrategyDeliveryType.ftRandomAmount
            self.isNFT = false
            self.deliveryTokenType = tokenType
            self.maxClaimableShares = maxClaimableShares
            self.claimedShares = 0
            self.totalAmount = totalAmount
            self.restAmount = totalAmount
        }
        // interface implement
        pub fun getTotalAmount(): UFix64 {
            return self.totalAmount
        }
        pub fun getRestAmount(): UFix64 {
            return self.restAmount
        }

        // ---- writable methods ----
        access(contract) fun deliverFT(treasury: &Treasury, recipient: &{FungibleToken.Receiver}): UFix64 {
            post {
                self.restAmount >= 0.0: "rest amount should be greator then zero."
            }
            var randShareAmount: UFix64 = 0.0
            if self.maxClaimableShares == self.claimedShares + 1 {
                randShareAmount = self.restAmount
            } else {
                let oneShareAmount = self.restAmount / UFix64(self.maxClaimableShares - self.claimedShares) * 0.5
                randShareAmount = oneShareAmount + oneShareAmount * UFix64(unsafeRandom() % 100) / 100.0
            }
            assert(self.restAmount >= randShareAmount, message: "rest amount is not enough.")

            // ensure enough
            treasury.ensureFTEnough(type: self.deliveryTokenType, amount: randShareAmount)

            // ensure type is same
            assert(recipient.getType() == self.deliveryTokenType, message: "Recipient identifier should be same as definition")
            let treasuryRef = &treasury.genericFTPool[self.deliveryTokenType] as &{FungibleToken.Provider, FungibleToken.Balance}?

            // do 'transfer' action
            let ft <- treasuryRef!.withdraw(amount: randShareAmount)
            // reduce the restAmount
            self.restAmount = self.restAmount - ft.balance
            recipient.deposit(from: <- ft)

            // add one to claimed
            self.claimedShares = self.claimedShares + 1

            return randShareAmount
        }
        access(contract) fun deliverNFT(treasury: &Treasury, recipient: &{NonFungibleToken.CollectionPublic}): [UInt64] {
            panic("This strategy without NFT delivery method")
        }
    }

    // StrategyDeliveryType.nft
    pub struct StrategyDeliverNFT: StrategyDelivery {
        // interface implement
        pub let type: StrategyDeliveryType
        pub let isNFT: Bool
        pub let deliveryTokenType: Type
        pub let maxClaimableShares: UInt64
        pub var claimedShares: UInt64

        init(
            _ tokenType: Type,
            _ maxClaimableShares: UInt64,
        ) {
            self.type = StrategyDeliveryType.nft
            self.isNFT = true
            self.deliveryTokenType = tokenType
            self.maxClaimableShares = maxClaimableShares
            self.claimedShares = 0
        }
        // interface implement
        pub fun getTotalAmount(): UFix64 { return 0.0 }
        pub fun getRestAmount(): UFix64 { return 0.0 }

        // ---- writable methods ----
        access(contract) fun deliverFT(treasury: &Treasury, recipient: &{FungibleToken.Receiver}): UFix64 {
            panic("This strategy without FT delivery method")
        }
        access(contract) fun deliverNFT(treasury: &Treasury, recipient: &{NonFungibleToken.CollectionPublic}): [UInt64] {
            // ensure enough
            treasury.ensureNFTEnough(type: self.deliveryTokenType, amount: 1)

            // ensure type is same
            assert(recipient.getType() == self.deliveryTokenType, message: "Recipient identifier should be same as definition")
            let treasuryRef = &treasury.genericNFTPool[self.deliveryTokenType] as &{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}?
            let ids = treasuryRef!.getIDs()

            let transferedIds: [UInt64] = []
            // do 'batch transfer' action
            let nft <- treasuryRef!.withdraw(withdrawID: ids.remove(at: unsafeRandom() % UInt64(ids.length)))
            assert(nft.getType().identifier == self.deliveryTokenType.identifier, message: "Recipient identifier should be same as definition")

            transferedIds.append(nft.id)
            recipient.deposit(token: <- nft)

            // add one to claimed
            self.claimedShares = self.claimedShares + 1

            return transferedIds
        }
    }

    pub struct StrategyInformation {
        // when claimed, if score will be consumed
        pub let consumable: Bool
        // minimium threshold of achievement score
        pub let threshold: UInt64
        // delivery inforamtion
        pub let delivery: {StrategyDelivery}

        // current strategy stage
        pub var currentState: StrategyState

        init(
            _ consumable: Bool,
            _ threshold: UInt64,
            _ delivery: {StrategyDelivery}
        ) {
            pre {
                threshold > 0: "Threshold must be bigger than zero"
                delivery.maxClaimableShares > 0: "claimable amount must be bigger than zero"
            }
            self.consumable = consumable
            self.threshold = threshold
            self.delivery = delivery
            // variable
            self.currentState = StrategyState.preparing
        }

        // set current state
        access(contract) fun setCurrentState(value: StrategyState) {
            self.currentState = value
        }

        // clone an object
        access(contract) fun clone(): StrategyInformation {
            let ret = StrategyInformation(
                self.consumable,
                self.threshold,
                self.delivery
            )
            ret.currentState = self.currentState
            return ret
        }
    }

    // the general strategy controller
    pub resource StrategyController {
        // basic info
        access(self) let info: StrategyInformation
        access(self) let claimed: [Address]

        init(
            consumable: Bool,
            threshold: UInt64,
            delivery: {StrategyDelivery}
        ) {
            self.info = StrategyInformation(consumable, threshold, delivery)
            self.claimed = []
        }

        // get a copy of strategy information
        pub fun getInfo(): StrategyInformation {
            return self.info.clone()
        }

        // get current state of the strategy
        pub fun getCurrentState(): StrategyState {
            return self.info.currentState
        }

        // get total shares of the strategy
        pub fun getTotalShares(): UInt64 {
            return self.info.delivery.maxClaimableShares
        }

        // get claimed shares of the strategy
        pub fun getClaimedShares(): UInt64 {
            return self.info.delivery.claimedShares
        }

        // get claimed addresses
        pub fun getClaimedAddresses(): [Address] {
            return self.claimed
        }

        // if user has claimed
        pub fun hasClaimed(address: Address): Bool {
            return self.claimed.contains(address)
        }

        // execute and go next
        access(contract) fun nextStage(): StrategyState {
            pre {
                self.info.currentState != StrategyState.closed: "Strategy is closed"
            }
            self.info.setCurrentState(value: StrategyState(rawValue: self.info.currentState.rawValue + 1)!)
            return self.info.currentState
        }

        // ---------- claimable Stage ----------

        // verify if the state is claimable and 
        // claim one share
        access(contract) fun claimOneShareFromTreasury(treasury: &Treasury, user: &{AchievementPublic}) {
            pre {
                self.info.currentState == StrategyState.claimable: "Ensure current stage is claimable."
                self.info.delivery.claimedShares < self.info.delivery.maxClaimableShares: "Reach max claimable."
                !self.hasClaimed(address: user.getOwner()): "The user has claimed one share."
                self.verifyScore(user: user): "Score not enough! The user cannot to claim for now."
            }

            let claimer = user.getOwner()
            let deliveryTokenType = self.info.delivery.deliveryTokenType

            // delivery for NFT
            if self.info.delivery.isNFT {
                let recipient = TokenRecipient(claimer, deliveryTokenType).getNFTCollectionPublic()
                // execute delivery
                let transferedIDs = self.info.delivery.deliverNFT(treasury: treasury, recipient: recipient)
                emit FLOATEventSeriesTreasuryNFTWithdraw(
                    seriesId: treasury.seriesId,
                    host: treasury.owner!.address,
                    identifier: deliveryTokenType.identifier,
                    ids: transferedIDs
                )
            } else {
            // delivery for FT
                let recipient = TokenRecipient(claimer, deliveryTokenType).getFungibleTokenReceiver()
                // execute delivery
                let transferedAmt = self.info.delivery.deliverFT(treasury: treasury, recipient: recipient)
                emit FLOATEventSeriesTreasuryTokenWithdraw(
                    seriesId: treasury.seriesId,
                    host: treasury.owner!.address,
                    identifier: deliveryTokenType.identifier,
                    amount: transferedAmt
                )
            }
            // add to claimed
            self.claimed.append(claimer)
        }

        // verify if user can claim this
        access(contract) fun verifyScore(user: &{AchievementPublic}): Bool {
            let thresholdScore = self.info.threshold
            var valid = false
            if self.info.consumable {
                valid = thresholdScore <= user.getConsumableScore()
            } else {
                valid = thresholdScore <= user.getTotalScore()
            }
            return valid
        }
    }

    // An interface that every "strategy" must implement.
    pub resource interface ITreasuryStrategy {
        // strategy general controler
        access(account) let controller: @StrategyController

        init(
            controller: @StrategyController,
            params: {String: AnyStruct}
        ) {
            post {
                self.controller.getInfo().currentState == StrategyState.preparing: "CurrentState should be preparing"
            }
        }

        // Fetch detail of the strategy
        pub fun getStrategyDetail(): AnyStruct

        // invoked when state changed
        access(account) fun onStateChanged(state: StrategyState)

        // ---------- opening Stage ----------

        // update user's achievement
        access(account) fun onGoalAccomplished(user: &{AchievementPublic}) {
            pre {
                self.controller.getInfo().currentState == StrategyState.opening: "Ensure current stage is opening."
            }
        }

        // ---------- claimable Stage ----------

        // verify if the user match the strategy
        access(account) fun verifyClaimable(user: &{AchievementPublic}): Bool {
            pre {
                self.controller.getInfo().currentState == StrategyState.claimable: "Ensure current stage is claimable."
            }
        }
    }

    // Tresury Collection
    //
    pub resource TreasuryCollection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // Dictionary to hold the NFTs in the Collection
        pub var depositedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.depositedNFTs <- {}
        }
        destroy() {
            destroy self.depositedNFTs
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.depositedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            return <- token
        }
        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.depositedNFTs[id] <- token

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.depositedNFTs.keys
        }

        // Returns a borrowed reference to an NFT in the collection
        // so that the caller can read data and call methods from it
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.depositedNFTs[id] as &NonFungibleToken.NFT?)!
        }
    }

    // temp collection in the treasury
    access(contract) fun createTreasuryCollection(): @TreasuryCollection {
        return <- create TreasuryCollection()
    }

    // Treasury public interface
    pub resource interface TreasuryPublic {
        // get token types from treasury
        pub fun getTreasuryAssets(isNFT: Bool): [Type]
        // get token balance from the token identifier
        pub fun getTreasuryTokenBalance(type: Type): &{FungibleToken.Balance}?
        // get nft collection public 
        pub fun getTreasuryNFTCollection(type: Type): &{NonFungibleToken.CollectionPublic}?
        // get all strategy information
        pub fun getStrategies(states: [StrategyState]?): [StrategyInformation]
        // For the public to check if some strategy is claimable
        pub fun isClaimable(strategyIndex: Int, user: &{AchievementPublic}): Bool
        // For the public to claim rewards
        pub fun claim(strategyIndex: Int, user: &{AchievementPublic})

        // borrow strategy reference
        access(contract) fun borrowStrategyRef(idx: Int): &{ITreasuryStrategy}
        // borrow strategies by state reference
        access(contract) fun borrowStrategiesRef(state: StrategyState?): [&{ITreasuryStrategy}]
    }

    // Treasury private interface
    pub resource interface TreasuryPrivate {
        // update drop receiver
        pub fun updateDropReceiver(receiver: Address)
        // drop all treasury, if no strategy alive
        pub fun dropTreasury()
        // deposit ft to treasury
        pub fun depositFungibleToken(from: @FungibleToken.Vault)
        // deposit nft to treasury
        pub fun depositNonFungibleTokens(nfts: @[NonFungibleToken.NFT])
        // add new strategy to the treasury
        pub fun addStrategy(strategy: @{ITreasuryStrategy}, autoStart: Bool)
        // update strategy status
        pub fun nextStrategyStage(idx: Int): StrategyState
    }

    // Treasury resource of each EventSeries (Optional)
    pub resource Treasury: TreasuryPublic, TreasuryPrivate {
        // Treasury seriesID
        pub let seriesId: UInt64
        // generic tokens will be dropped to this address, when treasury destory
        access(self) var receiver: Address
        // all treasury strategies
        access(self) var strategies: @[{ITreasuryStrategy}]
        // fungible token pool {identifier: Vault}
        access(contract) var genericFTPool: @{Type: FungibleToken.Vault}
        // non-fungible token pool {identifier: Collection}
        access(contract) var genericNFTPool: @{Type: {NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}}

        init(
            seriesId: UInt64,
            dropReceiver: Address
        ) {
            self.seriesId = seriesId
            self.receiver = dropReceiver

            self.genericFTPool <- {}
            self.genericNFTPool <- {}

            self.strategies <- []
        }

        destroy() {
            self.dropTreasury()

            destroy self.genericFTPool
            destroy self.genericNFTPool
            destroy self.strategies
        }

        // --- Getters - Public Interfaces ---

        pub fun getTreasuryAssets(isNFT: Bool): [Type] {
            if isNFT {
                return self.genericNFTPool.keys
            } else {
                return self.genericFTPool.keys
            }
        }

        pub fun getTreasuryTokenBalance(type: Type): &{FungibleToken.Balance}? {
            return &self.genericFTPool[type] as &{FungibleToken.Balance}?
        }

        pub fun getTreasuryNFTCollection(type: Type): &{NonFungibleToken.CollectionPublic}? {
            return &self.genericNFTPool[type] as &{NonFungibleToken.CollectionPublic}?
        }

        // get all strategy information
        pub fun getStrategies(states: [StrategyState]?): [StrategyInformation] {
            let infos: [StrategyInformation] = []
            let len = self.strategies.length
            var i = 0
            while i < len {
                let strategyRef = &self.strategies[i] as &{ITreasuryStrategy}
                let info = strategyRef.controller.getInfo()
                if states == nil || states!.contains(info.currentState) {
                    infos.append(info)
                }
                i = i + 1
            }
            return infos
        }
        
        // For the public to check if some strategy is claimable
        pub fun isClaimable(strategyIndex: Int, user: &{AchievementPublic}): Bool {
            // ensure achievement record should be same
            let achievementIdentifier = user.getTarget().toString()
            let seriesIdentifier = self.getParentIdentifier().toString()
            assert(achievementIdentifier == seriesIdentifier, message: "Achievement identifier should be same as event series identifier")

            // verify if user can claim
            let strategy = self.borrowStrategyRef(idx: strategyIndex)
            return strategy.verifyClaimable(user: user) && strategy.controller.verifyScore(user: user)
        }

        // execute claiming
        pub fun claim(
            strategyIndex: Int,
            user: &{AchievementPublic}
        ) {
            // ensure achievement record should be same
            let achievementIdentifier = user.getTarget().toString()
            let seriesIdentifier = self.getParentIdentifier().toString()
            assert(achievementIdentifier == seriesIdentifier, message: "Achievement identifier should be same as event series identifier")

            // verify if user can claim
            let strategy = self.borrowStrategyRef(idx: strategyIndex)
            assert(strategy.verifyClaimable(user: user), message: "Currently the user cannot to do claiming.")

            // distribute tokens
            let strategyInfo = strategy.controller.getInfo()
            let claimer = user.getOwner()

            // execute claim
            strategy.controller.claimOneShareFromTreasury(treasury: &self as &Treasury, user: user)

            // update achievement record
            user.treasuryClaimed(strategy: strategy)

            // emit claimed event
            emit FLOATEventSeriesTreasuryClaimed(
                seriesId: self.seriesId,
                host: self.owner!.address,
                strategyIdentifier: strategy.getType().identifier,
                index: strategyIndex,
                claimer: user.getOwner()
            )

            // check if all shares claimed, go next stage
            if strategy.controller.getClaimedShares() >= strategy.controller.getTotalShares() {
                self.nextStrategyStage(idx: strategyIndex)
            }
        }

        // --- Setters - Private Interfaces ---

        // update DropReceiver
        pub fun updateDropReceiver(receiver: Address) {
            self.receiver = receiver

            emit FLOATEventSeriesTreasuryUpdateDropReceiver(
                seriesId: self.seriesId,
                host: self.owner!.address,
                receiver: receiver
            )
        }

        // drop all treasury, if no strategy alive
        pub fun dropTreasury() {
            pre {
                self.strategies.length == self.getStrategies(states: [StrategyState.closed]).length
                    : "All strategies should be closed"
            }

            // FT will be withdrawed to owner
            for identifier in self.genericFTPool.keys {
                let recipient = TokenRecipient(self.receiver, identifier)
                let receiverReciever = recipient.getFungibleTokenReceiver()
                receiverReciever.deposit(from: <- self.genericFTPool.remove(key: identifier)!)
            }

            // NFT Token will be withdraw to owner
            for identifier in self.genericNFTPool.keys {
                let recipient = TokenRecipient(self.receiver, identifier)
                let receiverCollection = recipient.getNFTCollectionPublic()
                let collection = (&self.genericNFTPool[identifier] as &{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}?)!
                let keys = collection.getIDs()
                for id in keys {
                    receiverCollection.deposit(token: <- collection.withdraw(withdrawID: id))
                }
            }

            // treasury dropped
            emit FLOATEventSeriesTreasuryDropped(
                seriesId: self.seriesId,
                host: self.owner?.address,
                receiver: self.receiver
            )
        }

        // deposit ft to treasury
        pub fun depositFungibleToken(from: @FungibleToken.Vault) {
            let fromType = from.getType()
            let tokenInfo = FLOATEventSeries.getTokenDefinition(fromType)
                ?? panic("This token is not defined.")
            assert(!tokenInfo.isNFT, message: "This token should be FT.")
            assert(fromType == tokenInfo.type, message: "From identifier should be same as definition")

            let amount = from.balance
            var vaultRef = &self.genericFTPool[tokenInfo.type] as &{FungibleToken.Receiver}?
            if vaultRef == nil  {
                self.genericFTPool[tokenInfo.type] <-! from
            } else {
                vaultRef!.deposit(from: <- from)
            }

            emit FLOATEventSeriesTreasuryTokenDeposit(
                seriesId: self.seriesId,
                host: self.owner!.address,
                identifier: fromType.identifier,
                amount: amount
            )
        }

        // deposit nft to treasury
        pub fun depositNonFungibleTokens(nfts: @[NonFungibleToken.NFT]) {
            assert(nfts.length > 0, message: "Empty collection.")

            let nftType = (&nfts[0] as &NonFungibleToken.NFT).getType()
            let tokenInfo = FLOATEventSeries.getTokenDefinition(nftType)
                ?? panic("This token is not defined.")
            assert(tokenInfo.isNFT, message: "This token should be NFT.")
            assert(nftType == tokenInfo.type, message: "From identifier should be same as definition")

            let ids: [UInt64] = []
            var collectionRef: &{NonFungibleToken.CollectionPublic}? = &self.genericNFTPool[nftType] as &{NonFungibleToken.CollectionPublic}?
            if collectionRef == nil {
                self.genericNFTPool[nftType] <-! FLOATEventSeries.createTreasuryCollection()
                collectionRef = &self.genericNFTPool[nftType] as &{NonFungibleToken.CollectionPublic}?
            }

            let len = nfts.length
            var i = 0
            while i < len {
                let first <- nfts.removeFirst()
                assert(first.getType().identifier == nftType.identifier, message: "nfts identifier should be same.")
                collectionRef!.deposit(token: <- first)
                i = i + 1
            }
            // delete empty collection
            destroy nfts

            emit FLOATEventSeriesTreasuryNFTDeposit(
                seriesId: self.seriesId,
                host: self.owner!.address,
                identifier: nftType.identifier,
                ids: ids
            )
        }

        // add a new strategy
        pub fun addStrategy(strategy: @{ITreasuryStrategy}, autoStart: Bool) {
            // if autoStart is true and preparing, go next stage
            if autoStart && strategy.controller.getInfo().currentState == StrategyState.preparing {
                strategy.controller.nextStage()
            }

            let id = strategy.getType().identifier
            // ensure FTs and NFTs is enough in the treasury
            let info = strategy.controller.getInfo()
            if !info.delivery.isNFT {
                self.ensureFTEnough(type: info.delivery.deliveryTokenType, amount: info.delivery.getTotalAmount())
            } else {
                self.ensureNFTEnough(type: info.delivery.deliveryTokenType, amount: info.delivery.maxClaimableShares)
            }

            // add to strategies
            self.strategies.append(<- strategy)

            let host = self.owner!.address
            // update global
            let global = FLOATEventSeries.borrowEventSeriesGlobal()
            global.seriesUpdateTreasuryStrategy(host, seriesId: self.seriesId)

            emit FLOATEventSeriesTreasuryStrategyAdded(
                seriesId: self.seriesId,
                host: host,
                strategyIdentifier: id,
                index: self.strategies.length - 1
            )
        }

        // go next strategy stage
        pub fun nextStrategyStage(idx: Int): StrategyState {
            let strategy = self.borrowStrategyRef(idx: idx)
            let currentState = strategy.controller.getInfo().currentState

            // go to next stage
            let ret = strategy.controller.nextStage()
            // execute on state changed
            strategy.onStateChanged(state: ret)

            let host = self.owner!.address
            // update global
            let global = FLOATEventSeries.borrowEventSeriesGlobal()
            global.seriesUpdateTreasuryStrategy(host, seriesId: self.seriesId)

            emit FLOATEventSeriesTreasuryStrategyNextStage(
                seriesId: self.seriesId,
                host: host,
                strategyIdentifier: strategy.getType().identifier,
                index: idx,
                stage: ret.rawValue
            )
            return ret
        }

        // --- Setters - Contract Only ---

        // borrow strategy reference
        access(contract) fun borrowStrategyRef(idx: Int): &{ITreasuryStrategy} {
            pre {
                idx >= 0 && idx < self.strategies.length: "Strategy does not exist."
            }
            return &self.strategies[idx] as &{ITreasuryStrategy}
        }

        // borrow strategies by state reference
        access(contract) fun borrowStrategiesRef(state: StrategyState?): [&{ITreasuryStrategy}] {
            let ret: [&{ITreasuryStrategy}] = []
            let len = self.strategies.length
            var i = 0
            while i < len {
                let strategyRef = &self.strategies[i] as &{ITreasuryStrategy}
                let info = strategyRef.controller.getInfo()
                if state == nil || state! == info.currentState {
                    ret.append(strategyRef)
                }
                i = i + 1
            }
            return ret
        }

        // --- Self Only ---

        // ensure FT is enough
        access(contract) fun ensureFTEnough(type: Type, amount: UFix64) {
            let tokenInfo = FLOATEventSeries.getTokenDefinition(type)
                ?? panic("This token is not defined.")
            assert(!tokenInfo.isNFT, message: "This token should be FT.")
            assert(tokenInfo.type == type, message: "The identifer of input and definition should be same")
            assert(self.genericFTPool[tokenInfo.type] != nil, message: "There is no ft in the treasury.")

            // ensure amount enough
            let treasuryRef = &self.genericFTPool[tokenInfo.type] as &{FungibleToken.Balance}?
            assert(treasuryRef!.balance >= amount, message: "The balance is not enough.")
        }

        // ensure NFT is enough
        access(contract) fun ensureNFTEnough(type: Type, amount: UInt64) {
            let tokenInfo = FLOATEventSeries.getTokenDefinition(type)
                ?? panic("This token is not defined.")
            assert(tokenInfo.isNFT, message: "This token should be NFT.")
            assert(tokenInfo.type == type, message: "The identifer of input and definition should be same")
            assert(self.genericNFTPool[tokenInfo.type] != nil, message: "There is no nft in the treasury.")

            // ensure amount enough
            let treasuryRef = &self.genericNFTPool[tokenInfo.type] as &{NonFungibleToken.CollectionPublic}?
            let ids = treasuryRef!.getIDs()
            assert(ids.length > 0 && UInt64(ids.length) >= amount, message: "NFTs is not enough.")
        }

        // get identifier
        access(self) fun getParentIdentifier(): EventSeriesIdentifier {
            return EventSeriesIdentifier(self.owner!.address, self.seriesId)
        }
    }

    // A public interface to read EventSeries
    pub resource interface EventSeriesPublic {
        // ---- Members ----
        pub let sequence: UInt64
        // event basic display info
        pub var name: String
        pub var description: String
        pub var image: String

        // ---- Methods ----
        // get series id
        pub fun getID(): UInt64
        // get series identifier
        pub fun getIdentifier(): EventSeriesIdentifier
        // get last slot index
        pub fun getLastSlotIdx(): Int
        // get all slots data
        pub fun getSlots(): [{EventSlot}]
        // get a event slot by index
        pub fun getSlot(idx: Int): {EventSlot}
        // get all goals data
        pub fun getGoals(): [{IAchievementGoal}]
        // get an achievement goal by index
        pub fun getGoal(idx: Int): {IAchievementGoal}
        // check if goals of this user reached
        pub fun checkGoalsReached(user: Address, idxs: [Int]?): [Bool]
        // borrow the treasury public reference
        pub fun borrowTreasury(): &Treasury{TreasuryPublic}
    }

    // A private interface to write for EventSeries
    pub resource interface EventSeriesPrivate {
        // borrow the treasury private reference
        pub fun borrowTreasuryPrivate(): &Treasury{TreasuryPublic, TreasuryPrivate}
        // update basic information
        pub fun updateBasics(name: String, description: String, image: String)
        // update slot identifier information
        pub fun updateSlotData(idx: Int, identifier: EventIdentifier)
        // add a new achievement goal to the event series
        pub fun addAchievementGoal(goal: {IAchievementGoal})
    }

    // The event series defination
    pub resource EventSeries: EventSeriesPublic, EventSeriesPrivate, MetadataViews.Resolver {
        pub let sequence: UInt64
        pub let host: Address
        // --- basics ---
        pub var name: String
        pub var description: String
        pub var image: String

        access(account) var extra: {String: AnyStruct}
        // --- data ---
        // FLOAT slots
        access(account) let slots: [{EventSlot}]
        // Achievement goals
        access(account) let goals: [{IAchievementGoal}]
        // nest resource for the EventSeries treasury
        access(contract) var treasury: @Treasury

        init(
            host: Address,
            name: String,
            description: String,
            image: String,
            slots: [{EventSlot}],
            goals: [{IAchievementGoal}],
            _ extra: {String: AnyStruct}
        ) {
            self.sequence = FLOATEventSeries.totalEventSeries
            self.host = host

            self.name = name
            self.description = description
            self.image = image

            self.goals = goals

            for slot in slots {
                // ensure required slot is valid
                if slot.isInstance(Type<RequiredEventSlot>()) {
                    slot.getIdentifier()!.getEventPublic()
                }
            }
            self.slots = slots

            self.treasury <- create Treasury(
                seriesId: self.uuid,
                dropReceiver: host
            )
            self.extra = extra

            FLOATEventSeries.totalEventSeries = FLOATEventSeries.totalEventSeries + 1
        }

        destroy() {
            destroy self.treasury
        }

        // --- Getters - Public Interfaces ---

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<EventSeriesIdentifier>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name, 
                        description: self.description, 
                        thumbnail: MetadataViews.IPFSFile(cid: self.image, path: nil)
                    )
                case Type<EventSeriesIdentifier>():
                    return self.getIdentifier()
            }
            return nil
        }

        pub fun getID(): UInt64 {
            return self.uuid
        }
        
        pub fun getIdentifier(): EventSeriesIdentifier {
            return EventSeriesIdentifier(self.owner!.address, self.uuid)
        }

        pub fun getLastSlotIdx(): Int {
            return self.slots.length
        }

        pub fun getSlots(): [{EventSlot}] {
            return self.slots
        }

        pub fun getSlot(idx: Int): {EventSlot} {
            pre {
                idx >= 0 && idx < self.slots.length: "Slot does not exist."
            }
            return self.slots[idx]
        }

        pub fun getGoals(): [{IAchievementGoal}] {
            return self.goals
        }

        pub fun getGoal(idx: Int): {IAchievementGoal} {
            pre {
                idx >= 0 && idx < self.goals.length: "Goal does not exist."
            }
            return self.goals[idx]
        }

        pub fun borrowTreasury(): &Treasury{TreasuryPublic} {
            return &self.treasury as &Treasury{TreasuryPublic}
        }

        // check if goals of this user reached
        pub fun checkGoalsReached(user: Address, idxs: [Int]?): [Bool] {
            let ret: [Bool] = []
            var checkingGoals: [{IAchievementGoal}] = []
            if let includeIndexes = idxs {
                for idx in includeIndexes {
                    assert(idx >= 0 && idx < self.goals.length, message: "Goal does not exist.")
                    checkingGoals.append(self.goals[idx]!)
                }
            } else {
                checkingGoals = self.goals
            }
            // get
            for goal in checkingGoals {
                ret.append(goal.verify(&self as &{EventSeriesPublic}, user: user))
            }
            return ret
        }

        // --- Setters - Private Interfaces ---

        // borrow the treasury private reference
        pub fun borrowTreasuryPrivate(): &Treasury{TreasuryPublic, TreasuryPrivate} {
            return &self.treasury as &Treasury{TreasuryPublic, TreasuryPrivate}
        }

        pub fun updateBasics(name: String, description: String, image: String) {
            self.name = name
            self.description = description
            self.image = image

            emit FLOATEventSeriesBasicsUpdated(
                seriesId: self.uuid,
                host: self.host,
                name: name,
                description: description,
                image: image
            )
        }

        pub fun updateSlotData(idx: Int, identifier: EventIdentifier) {
            pre {
                idx < self.slots.length: "The idx is out of Slots size."
            }
            let slot = self.slots[idx]
            assert(slot.isInstance(Type<OptionalEventSlot>()) || slot.isInstance(Type<EmptyEventSlot>()), message: "The slot should be writable")
            // ensure event public exist
            identifier.getEventPublic()

            // update identifier information
            self.slots[idx].setIdentifier(identifier)

            emit FLOATEventSeriesSlotUpdated(
                seriesId: self.uuid,
                host: self.host,
                index: idx,
                eventHost: identifier.host,
                eventId: identifier.id
            )
        }

        pub fun addAchievementGoal(goal: {IAchievementGoal}) {
            self.goals.append(goal)

            let global = FLOATEventSeries.borrowEventSeriesGlobal()
            global.seriesUpdateGoals(self.host, seriesId: self.uuid)

            emit FLOATEventSeriesGoalAdded(
                seriesId: self.uuid,
                host: self.host,
                goalTitle: goal.title,
                points: goal.getPoints()
            )
        }

        // --- Setters - Contract Only ---

        // --- Self Only ---

    }

    // A public interface to read EventSeriesBuilder
    pub resource interface EventSeriesBuilderPublic {
        // ---- Members ----
        pub let sequence: UInt64
        // ---- Methods ----
        // get all ids including revoked
        pub fun getEventSeriesIDs(): [UInt64]
        // check if some id is revoked
        pub fun isRevoked(seriesId: UInt64): Bool
        // borrow the public interface of EventSeries
        pub fun borrowEventSeries(seriesId: UInt64): &EventSeries{EventSeriesPublic}?
        // internal full reference borrowing
        access(account) fun borrowEventSeriesBuilderFullRef(): &EventSeriesBuilder
    }

    // A private interface to write for EventSeriesBuilder
    pub resource interface EventSeriesBuilderPrivate {
        // create a new event series
        pub fun createEventSeries(
            name: String,
            description: String,
            image: String,
            slots: [{EventSlot}],
            goals: [{IAchievementGoal}],
            extra: {String: AnyStruct}
        ): UInt64
        // revoke a event series.
        pub fun revokeEventSeries(seriesId: UInt64)
        // recover a event series.
        pub fun recoverEventSeries(seriesId: UInt64)

        // registor a token info for general usage
        pub fun registerToken(path: PublicPath, isNFT: Bool)

        // create strategy controller
        pub fun createStrategyController(
            consumable: Bool,
            threshold: UInt64,
            delivery: {StrategyDelivery}
        ): @StrategyController

        // borrow event series private ref
        pub fun borrowEventSeriesPrivate(seriesId: UInt64): &EventSeries{EventSeriesPublic, EventSeriesPrivate}?
    }

    // the event series resource collection
    pub resource EventSeriesBuilder: EventSeriesBuilderPublic, EventSeriesBuilderPrivate, MetadataViews.ResolverCollection {
        pub let sequence: UInt64

        access(account) var series: @{UInt64: EventSeries}
        access(account) var revoked: @{UInt64: EventSeries}

        init() {
            self.series <- {}
            self.revoked <- {}

            self.sequence = FLOATEventSeries.totalEventSeriesBuilder

            emit FLOATEventSeriesBuilderCreated(sequence: self.sequence)

            FLOATEventSeries.totalEventSeriesBuilder = FLOATEventSeries.totalEventSeriesBuilder + 1
        }

        destroy() {
            destroy self.series
            destroy self.revoked
        }

        // --- Getters - Public Interfaces ---
        
        pub fun getIDs(): [UInt64] {
            return self.series.keys
        }

        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
            return (&self.series[id] as &{MetadataViews.Resolver}?) ?? panic("Faild to borrow ViewResolver.")
        }

        pub fun borrowEventSeries(seriesId: UInt64): &EventSeries{EventSeriesPublic}? {
            return &self.series[seriesId] as &EventSeries{EventSeriesPublic}?
        }

        pub fun getEventSeriesIDs(): [UInt64] {
            return self.series.keys.concat(self.revoked.keys)
        }

        pub fun isRevoked(seriesId: UInt64): Bool {
            return self.revoked[seriesId] != nil
        }
        
        // Maps the eventId to the name of that
        // event series. Just a kind helper.
        pub fun getAllEventSeries(_ revoked: Bool): {UInt64: String} {
            let answer: {UInt64: String} = {}
            let keys = revoked ? self.revoked.keys : self.series.keys
            for id in keys {
                if revoked {
                    answer[id] = (&self.revoked[id] as &EventSeries?)!.name
                } else {
                    answer[id] = (&self.series[id] as &EventSeries?)!.name
                }
            }
            return answer
        }

        // --- Setters - Private Interfaces ---

        pub fun createEventSeries(
            name: String,
            description: String,
            image: String,
            slots: [{EventSlot}],
            goals: [{IAchievementGoal}],
            extra: {String: AnyStruct}
        ): UInt64 {
            let host = self.owner!.address

            let eventSeries <- create EventSeries(
                host: host,
                name: name,
                description: description,
                image: image,
                slots: slots,
                goals: goals,
                extra
            )
            let seriesId = eventSeries.uuid
            self.series[seriesId] <-! eventSeries

            emit FLOATEventSeriesCreated(
                seriesId: seriesId,
                host: host,
                name: name,
                description: description,
                image: image
            )

            return seriesId
        }

        pub fun revokeEventSeries(seriesId: UInt64) {
            let one <- self.series.remove(key: seriesId) ?? panic("The event series does not exist")
            self.revoked[seriesId] <-! one
            
            emit FLOATEventSeriesRevoked(seriesId: seriesId, host: self.owner!.address)
        }

        pub fun recoverEventSeries(seriesId: UInt64) {
            let one <- self.revoked.remove(key: seriesId) ?? panic("The event series does not exist")
            self.series[seriesId] <-! one

            emit FLOATEventSeriesRecovered(seriesId: seriesId, host: self.owner!.address)
        }

        pub fun registerToken(path: PublicPath, isNFT: Bool) {
            // register token from owner's capability
            let tokenCap = self.owner!.getCapability(path)
            if isNFT {
                let collection = tokenCap.borrow<&{NonFungibleToken.CollectionPublic}>()
                    ?? panic("Could not borrow the &{NonFungibleToken.CollectionPublic}")
                let id = collection.getIDs().removeFirst()
                let nft = collection.borrowNFT(id: id)
                FLOATEventSeries.setTokenDefintion(token: nft.getType(), path: path, isNFT: true)
            } else {
                let ft = tokenCap.borrow<&{FungibleToken.Receiver}>()
                    ?? panic("Could not borrow the &{FungibleToken.Receiver}")
                FLOATEventSeries.setTokenDefintion(token: ft.getType(), path: path, isNFT: false)
            }
        }

        // create the controller resource
        pub fun createStrategyController(
            consumable: Bool,
            threshold: UInt64,
            delivery: {StrategyDelivery}
        ): @StrategyController {
            return <- create StrategyController(
                consumable: consumable,
                threshold: threshold,
                delivery: delivery
            )
        }

        pub fun borrowEventSeriesPrivate(seriesId: UInt64): &EventSeries{EventSeriesPublic, EventSeriesPrivate}? {
            return &self.series[seriesId] as &EventSeries{EventSeriesPublic, EventSeriesPrivate}?
        }

        // --- Setters - Contract Only ---

        access(account) fun borrowEventSeriesBuilderFullRef(): &EventSeriesBuilder {
            return &self as &EventSeriesBuilder
        }

        // --- Self Only ---

    }

    // ---- Shared global resources ----
    
    pub resource interface EventSeriesGlobalPublic {
        // get series identifier
        pub fun querySeries(page: UInt64, limit: UInt64, isTreasuryAvailable: Bool): [EventSeriesIdentifier]
        // get series amount
        pub fun getTotalAmount(isTreasuryAvailable: Bool): Int
        // add a event series with goal to global
        access(contract) fun seriesUpdateGoals(_ host: Address, seriesId: UInt64)
        // update event series by its treasury strategy
        access(contract) fun seriesUpdateTreasuryStrategy(_ host: Address, seriesId: UInt64)
    }

    pub resource EventSeriesGlobal: EventSeriesGlobalPublic {
        access(self) var seriesList: [String]
        access(self) var seriesWithTreasuryAvailableList: [String]
        access(self) var seriesMapping: {String: EventSeriesIdentifier}

        init() {
            self.seriesMapping = {}
            self.seriesList = []
            self.seriesWithTreasuryAvailableList = []
        }

        // --- Getters - Public Interfaces ---

        pub fun querySeries(page: UInt64, limit: UInt64, isTreasuryAvailable: Bool): [EventSeriesIdentifier] {
            let arr = isTreasuryAvailable ? self.seriesWithTreasuryAvailableList : self.seriesList
            let startAt = Int(page.saturatingMultiply(limit))
            assert(startAt < arr.length, message: "page is out of bound")

            let endAt = startAt + Int(limit) > arr.length ? arr.length : startAt + Int(limit)
            let names = arr.slice(from: startAt, upTo: endAt)

            let ret: [EventSeriesIdentifier] = []
            for name in names {
                let id = self.seriesMapping[name]
                assert(id != nil, message: "Invalid series key:".concat(name))
                ret.append(id!)
            }
            return ret
        }

        pub fun getTotalAmount(isTreasuryAvailable: Bool): Int {
            let arr = isTreasuryAvailable ? self.seriesWithTreasuryAvailableList : self.seriesList
            return arr.length
        }

        // --- Setters - Contract Only ---

        // add a event series with goal to global
        access(contract) fun seriesUpdateGoals(_ host: Address, seriesId: UInt64) {
            let id = EventSeriesIdentifier(host, seriesId)
            let key = id.toString()
            // Already exists
            if self.seriesMapping.containsKey(key) {
                return
            }

            // ensure event series exists
            id.getEventSeriesPublic()
            assert(!self.seriesList.contains(key), message: "Already exists, key:".concat(key))

            self.seriesMapping[key] = id
            self.seriesList.insert(at: 0, key)

            emit FLOATEventSeriesGlobalAddedToList(seriesId: seriesId, host: host)
        }

        // update event series by its treasury strategy 
        access(contract) fun seriesUpdateTreasuryStrategy(_ host: Address, seriesId: UInt64) {
            let id = EventSeriesIdentifier(host, seriesId)
            let key = id.toString()
            assert(self.seriesMapping.containsKey(key), message: "Key does not exist")

            // ensure event series exists
            let eventSeries = id.getEventSeriesPublic()
            let treasury = eventSeries.borrowTreasury()
            let availableStrategies = treasury.getStrategies(states: [
                StrategyState.preparing,
                StrategyState.opening,
                StrategyState.claimable
            ])

            var updated = false
            if availableStrategies.length > 0 && !self.seriesWithTreasuryAvailableList.contains(key) {
                self.seriesWithTreasuryAvailableList.insert(at: 0, key)
                updated = true
            } else {
                // remove key
                let index = self.seriesWithTreasuryAvailableList.firstIndex(of: key)
                if index != nil {
                    self.seriesWithTreasuryAvailableList.remove(at: index!)
                    updated = true
                }
                // update to first
                if availableStrategies.length > 0 {
                    self.seriesWithTreasuryAvailableList.insert(at: 0, key)
                    updated = true
                }
            }

            if updated {
                emit FLOATEventSeriesGlobalTreasuryStrategyUpdated(seriesId: seriesId, host: host)
            }
        }

        // --- Self Only ---
    }

    // ---- data For Endusers ----

    // Achievement public interface
    pub resource interface AchievementPublic {
        // get achievement record owner
        pub fun getOwner(): Address
        // get achievement record target
        pub fun getTarget(): EventSeriesIdentifier
        // get total score
        pub fun getTotalScore(): UInt64
        // get current comsumable score
        pub fun getConsumableScore(): UInt64
        // get all finished goals
        pub fun getFinishedGoals(): [Int]
        // check if goal can be accomplished
        pub fun isGoalReady(goalIdx: Int): Bool

        // Update treasury claimed information
        access(contract) fun treasuryClaimed(strategy: &{ITreasuryStrategy})
    }

    // Achievement private interface
    pub resource interface AchievementWritable {
        // execute verify and accomplish 
        pub fun accomplishGoal(goalIdx: Int)
    }

    // Users' Achevement of one EventSeries
    pub resource Achievement: AchievementPublic, AchievementWritable {
        // target to event identifier
        access(self) let target: EventSeriesIdentifier
        // current achievement score
        access(account) var score: UInt64
        // current consumable achievement score
        access(account) var consumableScore: UInt64
        // all finished goals 
        access(account) var finishedGoals: [Int]

        init(
            host: Address,
            seriesId: UInt64
        ) {
            self.score = 0
            self.consumableScore = 0
            self.finishedGoals = []

            self.target = EventSeriesIdentifier(host, seriesId)
        }

        // --- Getters - Public Interfaces ---

        // get achievement record owner
        pub fun getOwner(): Address {
            return self.owner!.address
        }

        // get achievement record target
        pub fun getTarget(): EventSeriesIdentifier {
            return self.target
        }

        // get total score
        pub fun getTotalScore(): UInt64 {
            return self.score
        }

        // get current comsumable score
        pub fun getConsumableScore(): UInt64 {
            return self.consumableScore
        }

        // get all finished goals
        pub fun getFinishedGoals(): [Int] {
            return self.finishedGoals
        }

        // check if goal can be accomplished
        pub fun isGoalReady(goalIdx: Int): Bool {
            // fetch the event series reference
            let eventSeriesRef = self.getTarget().getEventSeriesPublic()
            let goal = eventSeriesRef.getGoal(idx: goalIdx)

            return goal.verify(eventSeriesRef, user: self.owner!.address)
        }

        // --- Setters - Private Interfaces ---

        // Achieve the goal and add to score
        pub fun accomplishGoal(goalIdx: Int) {
            pre {
                !self.finishedGoals.contains(goalIdx): "The goal is already accomplished."
            }

            // fetch the event series reference
            let eventSeriesRef = self.getTarget().getEventSeriesPublic()
            let goal = eventSeriesRef.getGoal(idx: goalIdx)

            // verify first. if not allowed, the method will panic
            assert(goal.verify(eventSeriesRef, user: self.owner!.address), message: "Failed to verify goal")

            // add to score
            let point = goal.getPoints()
            self.score = self.score.saturatingAdd(point)
            self.consumableScore = self.consumableScore.saturatingAdd(point)

            // update achievement to all opening treasury strategies
            let treasury = eventSeriesRef.borrowTreasury()
            let openingStrategies = treasury.borrowStrategiesRef(state: StrategyState.opening)
            for strategy in openingStrategies {
                strategy.onGoalAccomplished(user: &self as &{AchievementPublic})
            }

            // add to finished goal
            self.finishedGoals.append(goalIdx)

            // emit event
            emit FLOATAchievementGoalAccomplished(
                seriesId: eventSeriesRef.getID(),
                host: eventSeriesRef.owner!.address,
                owner: self.owner!.address,
                goalIdx: goalIdx
            )
        }

        // --- Setters - Contract Only ---

        // Update treasury claimed information
        access(contract) fun treasuryClaimed(strategy: &{ITreasuryStrategy}) {
            let info = strategy.controller.getInfo()
            // only consumable strategy will update score
            if info.consumable {
                assert(self.consumableScore >= info.threshold, message: "Consumable score is not enough.")

                self.consumableScore = self.consumableScore.saturatingSubtract(info.threshold)
            }
        }

        // --- Self Only ---

    }

    // A public interface to read AchievementBoard
    pub resource interface AchievementBoardPublic {
        // get the achievement reference by event series identifier
        pub fun borrowAchievementRecordRef(host: Address, seriesId: UInt64): &{AchievementPublic}?
    }

    // A private interface to write AchievementBoard
    pub resource interface AchievementBoardPrivate {
        // create achievement by host and id
        pub fun createAchievementRecord(host: Address, seriesId: UInt64): EventSeriesIdentifier
        // get the achievement record reference by event series identifier
        pub fun borrowAchievementRecordWritable(host: Address, seriesId: UInt64): &{AchievementPublic, AchievementWritable}?
    }

    // Users' Achievement board
    pub resource AchievementBoard: AchievementBoardPublic, AchievementBoardPrivate {
        pub let sequence: UInt64
        // all achievement resources
        access(account) var achievements: @{String: Achievement}

        init() {
            self.sequence = FLOATEventSeries.totalAchievementBoards
            self.achievements <- {}

            emit FLOATAchievementBoardCreated(
                sequence: self.sequence
            )

            FLOATEventSeries.totalAchievementBoards = FLOATEventSeries.totalAchievementBoards + 1
        }

        destroy() {
            destroy self.achievements
        }

        // --- Getters - Public Interfaces ---

        pub fun borrowAchievementRecordRef(host: Address, seriesId: UInt64): &{AchievementPublic}? {
            let target = EventSeriesIdentifier(host, seriesId)
            let key = target.toString()
            return &self.achievements[key] as &{AchievementPublic}?
        }

        // --- Setters - Private Interfaces ---

        // create achievement by host and id
        pub fun createAchievementRecord(host: Address, seriesId: UInt64): EventSeriesIdentifier {
            let identifier = EventSeriesIdentifier(host, seriesId)
            let key = identifier.toString()

            assert(self.achievements[key] == nil, message: "Achievement of the event series should be empty.")
            assert(identifier.getEventSeriesPublic() != nil , message: "The event series should exist")

            self.achievements[key] <-! create Achievement(
                host: host,
                seriesId: seriesId
            )

            emit FLOATAchievementRecordInitialized(
                seriesId: seriesId,
                host: host,
                owner: self.owner!.address
            )
            return identifier
        }

        pub fun borrowAchievementRecordWritable(host: Address, seriesId: UInt64): &{AchievementPublic, AchievementWritable}? {
            let target = EventSeriesIdentifier(host, seriesId)
            let key = target.toString()
            return &self.achievements[key] as &{AchievementPublic, AchievementWritable}?
        }

        // --- Setters - Contract Only ---

        // --- Self Only ---

    }

    // ---- contract methods ----

    pub fun createEventSeriesBuilder(): @EventSeriesBuilder {
        return <- create EventSeriesBuilder()
    }

    pub fun createAchievementBoard(): @AchievementBoard {
        return <- create AchievementBoard()
    }

    // borrow the reference of the EventSeriesGlobal
    pub fun borrowEventSeriesGlobal(): &EventSeriesGlobal{EventSeriesGlobalPublic} {
        return self.account.borrow<&EventSeriesGlobal{EventSeriesGlobalPublic}>(from: self.FLOATEventSeriesGlobalStoragePath)
            ?? panic("Failed to borrow EventSeriesGlobal")
    }

    init() {
        self.totalEventSeries = 0
        self.totalEventSeriesBuilder = 0
        self.totalAchievementBoards = 0
        self.tokenDefinitions = {}

        self.FLOATEventSeriesBuilderStoragePath = /storage/FLOATEventSeriesBuilderPath
        self.FLOATEventSeriesBuilderPrivatePath = /private/FLOATEventSeriesBuilderPath
        self.FLOATEventSeriesBuilderPublicPath = /public/FLOATEventSeriesBuilderPath

        self.FLOATAchievementBoardStoragePath = /storage/FLOATAchievementBoardPath
        self.FLOATAchievementBoardPublicPath = /public/FLOATAchievementBoardPath

        self.FLOATEventSeriesGlobalStoragePath = /storage/FLOATEventSeriesGlobalPath
        self.FLOATEventSeriesGlobalPublicPath = /public/FLOATEventSeriesGlobalPath

        self.account.save(<- create EventSeriesGlobal(), to: self.FLOATEventSeriesGlobalStoragePath)
        self.account.link<&EventSeriesGlobal{EventSeriesGlobalPublic}>(
            self.FLOATEventSeriesGlobalPublicPath,
            target: self.FLOATEventSeriesGlobalStoragePath
        )

        emit ContractInitialized()
    }
}
 