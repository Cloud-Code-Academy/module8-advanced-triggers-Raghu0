public with sharing class OpportunityTriggerHandler extends TriggerHandler{

    public override void beforeInsert(){
        OpportunityHelper.setOppType(Trigger.new);
    }
    public override void beforeUpdate(){
        OpportunityHelper.appendOppDesc(Trigger.new);
        OpportunityHelper.assignPrimaryContactWithTitleCEO(Trigger.new);
    }
    public override void afterInsert(){
        OpportunityHelper.taskForNewOpp(Trigger.new);
        OpportunityHelper.setOppType(Trigger.new); 
        /*Hi Reviewer, I included the 'setOppType', in the before insert trigger context but the test class failed. Later I moved this method to 
        afterInsert trigger context and updated the records, with Opp Type = 'New Customer'. I'm wondering the reason behind why this doesn't work
        in the beforeTrigger context. How do we decide in which Trigger Context, the method should be called? Thanks.
        */
    }
    public override void beforeDelete(){
        OpportunityHelper.closedWonOppDeletion(Trigger.old);
        OpportunityHelper.closedOppValidation(Trigger.old);
    }
    public override void afterUpdate(){
        OpportunityHelper.oppAmountValidation(Trigger.new);
        
    }
    public override void afterDelete(){
        OpportunityHelper.sendEmailWhenOppDeleted(Trigger.old);
    }
    public override void afterUndelete(){
            OpportunityHelper.assignPrimaryContactWithTitleVPSales(Trigger.new);
        
    }

}