@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'INTERFACE ORDEN DE TRABAJO'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_ORDEN_TRABAJO as select from ztorden
composition [0..*] of ZI_TAREA as _Tareas
{
    key uuid as Uuid,
    orden_num as OrdenNum,
    descripcion as Descripcion,
    status as Status,
    fecha_inicio as FechaInicio,
    fecha_fin as FechaFin,
    responsable as Responsable,
    created_at as CreatedAt,
    creared_by as CrearedBy,
    last_changed_at as LastChangedAt,
    last_changed_by as LastChangedBy,
    _Tareas
}
