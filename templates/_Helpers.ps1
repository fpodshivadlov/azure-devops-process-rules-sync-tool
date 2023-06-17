function Get-AzureDevOpsFieldName { 
   param (
      [Parameter(Mandatory=$true)]
      [string]
      $FriendlyFieldName
   )

   Switch ($FriendlyFieldName) {
      "Id" { "System.Id" }
      "Rev" { "System.Rev" }
      "WorkItemType" { "System.WorkItemType" }
      "State" { "System.State" }
      "Reason" { "System.Reason" }
      "Parent" { "System.Parent" }
      "Title" { "System.Title" }
      "Description" { "System.Description" }
      "Tags" { "System.Tags" }
      "AssignedTo" { "System.AssignedTo" }
      "AreaId" { "System.AreaId" }
      "AreaPath" { "System.AreaPath" }
      "IterationPath" { "System.IterationPath" }
      "IterationId" { "System.IterationId" }
      "IterationLevel1" { "System.IterationLevel1" }
      "IterationLevel2" { "System.IterationLevel2" }
      "IterationLevel3" { "System.IterationLevel3" }
      "IterationLevel4" { "System.IterationLevel4" }
      "IterationLevel5" { "System.IterationLevel5" }
      "IterationLevel6" { "System.IterationLevel6" }
      "BoardLane" { "System.BoardLane" }
      "ExternalLinkCount" { "System.ExternalLinkCount" }
      "HyperLinkCount" { "System.HyperLinkCount" }
      "AttachedFileCount" { "System.AttachedFileCount" }
      "RelatedLinkCount" { "System.RelatedLinkCount" }
      "RemoteLinkCount" { "System.RemoteLinkCount" }
      "CommentCount" { "System.CommentCount" }
      "Activity" { "Microsoft.VSTS.Common.Activity" }
      "Priority" { "Microsoft.VSTS.Common.Priority" }
      "Severity" { "Microsoft.VSTS.Common.Severity" }
      "Risk" { "Microsoft.VSTS.Common.Risk" }
      "ValueArea" { "Microsoft.VSTS.Common.ValueArea" }
      "AcceptanceCriteria" { "Microsoft.VSTS.Common.AcceptanceCriteria" }
      "StackRank" { "Microsoft.VSTS.Common.StackRank" }
      "ReproSteps" { "Microsoft.VSTS.TCM.ReproSteps" }
      "SystemInfo" { "Microsoft.VSTS.TCM.SystemInfo" }
      "IntegrationBuild" { "Microsoft.VSTS.Build.IntegrationBuild" }
      "FoundIn" { "Microsoft.VSTS.Build.FoundIn" }
      "StoryPoints" { "Microsoft.VSTS.Scheduling.StoryPoints" }
      "OriginalEstimate" { "Microsoft.VSTS.Scheduling.OriginalEstimate" }
      "RemainingWork" { "Microsoft.VSTS.Scheduling.RemainingWork" }
      "CompletedWork" { "Microsoft.VSTS.Scheduling.CompletedWork" }
      "StartDate" { "Microsoft.VSTS.Scheduling.StartDate" }
      "FinishDate" { "Microsoft.VSTS.Scheduling.FinishDate" }

      # Assuming custom:
      default { "Custom.$FriendlyFieldName" }
   }
}
