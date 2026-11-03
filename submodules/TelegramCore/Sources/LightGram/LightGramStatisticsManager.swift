import Foundation
import UIKit
import SwiftSignalKit
import Postbox

public enum StatisticsPeriod: Int, CaseIterable {
    case sevenDays = 0
    case thirtyDays = 1
    case allTime = 2
    
    public var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .allTime: return 0
        }
    }
}

public struct TopChatStat: Codable, Equatable {
    public let peerId: Int64
    public let title: String
    public let messageCount: Int
    public let percentage: Double
    public let peerType: String // "user", "group", "channel"
    
    public init(peerId: Int64, title: String, messageCount: Int, percentage: Double, peerType: String) {
        self.peerId = peerId
        self.title = title
        self.messageCount = messageCount
        self.percentage = percentage
        self.peerType = peerType
    }
}

public struct LightGramStatisticsSnapshot: Codable, Equatable {
    public let periodIndex: Int
    public let generatedTimestamp: Int32
    public let startDateTimestamp: Int32
    public let endDateTimestamp: Int32
    
    // Overview
    public let sentMessagesCount: Int
    public let receivedMessagesCount: Int
    public let totalMessagesCount: Int
    public let activeChatsCount: Int
    
    // Media Counts
    public let photosCount: Int
    public let videosCount: Int
    public let circlesCount: Int
    public let voiceCount: Int
    public let filesCount: Int
    
    // Activity Breakdown
    public let hourlyActivity: [Int] // 24 values: index 0 to 23
    public let dailyActivityLabels: [String]
    public let dailyActivityCounts: [Int]
    
    // Top Chats
    public let topChats: [TopChatStat]
    
    // Advanced Analytics
    public let peakDayLabel: String
    public let peakHourLabel: String
    public let averageMessagesPerDay: Double
    public let deletedMessagesCount: Int
    public let editedRevisionsCount: Int
    public let vaultItemsCount: Int
    public let vaultStorageFormatted: String
    public let isRealData: Bool
    
    public init(
        periodIndex: Int,
        generatedTimestamp: Int32 = Int32(Date().timeIntervalSince1970),
        startDateTimestamp: Int32,
        endDateTimestamp: Int32,
        sentMessagesCount: Int,
        receivedMessagesCount: Int,
        totalMessagesCount: Int,
        activeChatsCount: Int,
        photosCount: Int,
        videosCount: Int,
        circlesCount: Int,
        voiceCount: Int,
        filesCount: Int,
        hourlyActivity: [Int],
        dailyActivityLabels: [String],
        dailyActivityCounts: [Int],
        topChats: [TopChatStat],
        peakDayLabel: String,
        peakHourLabel: String,
        averageMessagesPerDay: Double,
        deletedMessagesCount: Int,
        editedRevisionsCount: Int,
        vaultItemsCount: Int,
        vaultStorageFormatted: String,
        isRealData: Bool
    ) {
        self.periodIndex = periodIndex
        self.generatedTimestamp = generatedTimestamp
        self.startDateTimestamp = startDateTimestamp
        self.endDateTimestamp = endDateTimestamp
        self.sentMessagesCount = sentMessagesCount
        self.receivedMessagesCount = receivedMessagesCount
        self.totalMessagesCount = totalMessagesCount
        self.activeChatsCount = activeChatsCount
        self.photosCount = photosCount
        self.videosCount = videosCount
        self.circlesCount = circlesCount
        self.voiceCount = voiceCount
        self.filesCount = filesCount
        self.hourlyActivity = hourlyActivity
        self.dailyActivityLabels = dailyActivityLabels
        self.dailyActivityCounts = dailyActivityCounts
        self.topChats = topChats
        self.peakDayLabel = peakDayLabel
        self.peakHourLabel = peakHourLabel
        self.averageMessagesPerDay = averageMessagesPerDay
        self.deletedMessagesCount = deletedMessagesCount
        self.editedRevisionsCount = editedRevisionsCount
        self.vaultItemsCount = vaultItemsCount
        self.vaultStorageFormatted = vaultStorageFormatted
        self.isRealData = isRealData
    }
}

public final class LightGramStatisticsManager {
    public static let shared = LightGramStatisticsManager()
    
    private let queue = DispatchQueue(label: "site.lightgram.statistics", qos: .userInitiated)
    private var snapshotsCache: [Int: LightGramStatisticsSnapshot] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func fetchStatistics(
        account: Account,
        period: StatisticsPeriod,
        forceRefresh: Bool = false,
        completion: @escaping (LightGramStatisticsSnapshot) -> Void
    ) {
        self.lock.lock()
        if !forceRefresh, let cached = self.snapshotsCache[period.rawValue] {
            let age = Int32(Date().timeIntervalSince1970) - cached.generatedTimestamp
            if age < 300 { // 5 minutes cache
                self.lock.unlock()
                completion(cached)
                return
            }
        }
        self.lock.unlock()
        
        self.queue.async {
            let now = Int32(Date().timeIntervalSince1970)
            let minTimestamp: Int32
            let daysInPeriod: Int
            switch period {
            case .sevenDays:
                minTimestamp = now - 7 * 86400
                daysInPeriod = 7
            case .thirtyDays:
                minTimestamp = now - 30 * 86400
                daysInPeriod = 30
            case .allTime:
                minTimestamp = 0
                daysInPeriod = 365
            }
            
            let _ = (account.postbox.transaction { transaction -> LightGramStatisticsSnapshot in
                var sentCount = 0
                var receivedCount = 0
                var photosCount = 0
                var videosCount = 0
                var circlesCount = 0
                var voiceCount = 0
                var filesCount = 0
                
                var hourlyCounts = [Int](repeating: 0, count: 24)
                var calendar = Calendar.current
                calendar.timeZone = TimeZone.current
                
                var peerMessageCounts: [PeerId: (title: String, count: Int, type: String)] = [:]
                
                // Get all root chat list peers
                var peersToScan: [Peer] = transaction.getChatListPeers(groupId: .root, filterPredicate: nil, additionalFilter: nil)
                let recentPeerIds = transaction.getRecentPeerIds()
                for rId in recentPeerIds {
                    if !peersToScan.contains(where: { $0.id == rId }) {
                        if let peer = transaction.getPeer(rId) {
                            peersToScan.append(peer)
                        }
                    }
                }
                
                var activeChats = 0
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "EEE"
                
                var dailyBuckets: [String: Int] = [:]
                var dailyOrder: [String] = []
                
                // Prepare daily labels for period
                let numDays = min(daysInPeriod, 7)
                for i in (0..<numDays).reversed() {
                    let d = Date(timeIntervalSince1970: TimeInterval(now - Int32(i * 86400)))
                    let label = dayFormatter.string(from: d)
                    if !dailyOrder.contains(label) {
                        dailyOrder.append(label)
                    }
                    dailyBuckets[label] = 0
                }
                
                for peer in peersToScan {
                    var peerMsgCount = 0
                    var peerHasActivityInPeriod = false
                    
                    transaction.withAllMessages(peerId: peer.id) { message -> Bool in
                        if message.timestamp < minTimestamp {
                            return true
                        }
                        
                        peerHasActivityInPeriod = true
                        peerMsgCount += 1
                        
                        let isIncoming = message.flags.contains(.Incoming)
                        if isIncoming {
                            receivedCount += 1
                        } else {
                            sentCount += 1
                        }
                        
                        // Media categorization
                        for m in message.media {
                            if let _ = m as? TelegramMediaImage {
                                photosCount += 1
                            } else if let file = m as? TelegramMediaFile {
                                if file.isInstantVideo {
                                    circlesCount += 1
                                } else if file.isVideo || file.mimeType.hasPrefix("video/") {
                                    videosCount += 1
                                } else if file.isVoice || file.mimeType.hasPrefix("audio/ogg") {
                                    voiceCount += 1
                                } else {
                                    filesCount += 1
                                }
                            }
                        }
                        
                        // Hourly calculation
                        let msgDate = Date(timeIntervalSince1970: TimeInterval(message.timestamp))
                        let hour = calendar.component(.hour, from: msgDate)
                        if hour >= 0 && hour < 24 {
                            hourlyCounts[hour] += 1
                        }
                        
                        // Daily calculation
                        let dayKey = dayFormatter.string(from: msgDate)
                        if let existing = dailyBuckets[dayKey] {
                            dailyBuckets[dayKey] = existing + 1
                        }
                        
                        return true
                    }
                    
                    if peerHasActivityInPeriod {
                        activeChats += 1
                        var title = peer.debugDisplayTitle
                        if title.isEmpty {
                            title = "Chat"
                        }
                        var type = "user"
                        if let channel = peer as? TelegramChannel {
                            type = channel.isGroup ? "group" : "channel"
                        } else if peer is TelegramGroup {
                            type = "group"
                        }
                        peerMessageCounts[peer.id] = (title: title, count: peerMsgCount, type: type)
                    }
                }
                
                let totalMessages = sentCount + receivedCount
                
                // Top chats calculation
                let sortedPeers = peerMessageCounts.sorted { $0.value.count > $1.value.count }
                let topPeersList = sortedPeers.prefix(5)
                var topChats: [TopChatStat] = []
                for entry in topPeersList {
                    let share = totalMessages > 0 ? (Double(entry.value.count) / Double(totalMessages)) * 100.0 : 0.0
                    topChats.append(TopChatStat(
                        peerId: entry.key.toInt64(),
                        title: entry.value.title,
                        messageCount: entry.value.count,
                        percentage: round(share * 10) / 10,
                        peerType: entry.value.type
                    ))
                }
                
                // Peak hour
                var maxHourIndex = 0
                var maxHourCount = -1
                for (h, count) in hourlyCounts.enumerated() {
                    if count > maxHourCount {
                        maxHourCount = count
                        maxHourIndex = h
                    }
                }
                let peakHourLabel = totalMessages > 0 ? String(format: "%02d:00 - %02d:00", maxHourIndex, (maxHourIndex + 1) % 24) : "N/A"
                
                // Peak day
                var peakDayLabel = "N/A"
                var maxDayCount = -1
                for (dayKey, count) in dailyBuckets {
                    if count > maxDayCount && count > 0 {
                        maxDayCount = count
                        peakDayLabel = dayKey
                    }
                }
                
                // Daily activity arrays
                var dailyLabels: [String] = []
                var dailyCounts: [Int] = []
                for label in dailyOrder {
                    dailyLabels.append(label)
                    dailyCounts.append(dailyBuckets[label] ?? 0)
                }
                
                // Avg messages / day
                let avgPerDay = daysInPeriod > 0 ? Double(totalMessages) / Double(daysInPeriod) : Double(totalMessages)
                
                // Spy Mode stats
                let deletedCount = LightGramSpyManager.shared.getDeletedRecordCount()
                let editCount = LightGramSpyManager.shared.getEditRecordCount()
                
                // Media vault stats
                let vaultItems = LightGramMediaVaultManager.shared.getItems()
                let vaultCount = vaultItems.count
                let vaultSize = LightGramMediaVaultManager.shared.formattedStorageSize()
                
                return LightGramStatisticsSnapshot(
                    periodIndex: period.rawValue,
                    startDateTimestamp: minTimestamp,
                    endDateTimestamp: now,
                    sentMessagesCount: sentCount,
                    receivedMessagesCount: receivedCount,
                    totalMessagesCount: totalMessages,
                    activeChatsCount: activeChats,
                    photosCount: photosCount,
                    videosCount: videosCount,
                    circlesCount: circlesCount,
                    voiceCount: voiceCount,
                    filesCount: filesCount,
                    hourlyActivity: hourlyCounts,
                    dailyActivityLabels: dailyLabels,
                    dailyActivityCounts: dailyCounts,
                    topChats: topChats,
                    peakDayLabel: peakDayLabel,
                    peakHourLabel: peakHourLabel,
                    averageMessagesPerDay: round(avgPerDay * 10) / 10,
                    deletedMessagesCount: deletedCount,
                    editedRevisionsCount: editCount,
                    vaultItemsCount: vaultCount,
                    vaultStorageFormatted: vaultSize,
                    isRealData: true
                )
            }).start(next: { snapshot in
                self.lock.lock()
                self.snapshotsCache[period.rawValue] = snapshot
                self.lock.unlock()
                
                DispatchQueue.main.async {
                    completion(snapshot)
                }
            })
        }
    }
}
