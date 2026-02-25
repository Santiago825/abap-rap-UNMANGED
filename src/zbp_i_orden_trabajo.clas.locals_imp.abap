CLASS lhc_ZI_ORDEN_TRABAJO DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    TYPES tt_ztorden TYPE STANDARD TABLE OF ztorden WITH EMPTY KEY.
    CLASS-DATA mt_buffer_insert TYPE tt_ztorden. " Buffer estático
    CLASS-DATA mt_buffer_update TYPE tt_ztorden.
    CLASS-DATA mt_buffer_delete TYPE tt_ztorden.

    " Buffers para Tareas (Entidad Hija)
    TYPES tt_ztarea TYPE STANDARD TABLE OF zttarea WITH EMPTY KEY.
    CLASS-DATA mt_buffer_tarea_ins TYPE tt_ztarea.
    CLASS-DATA mt_buffer_tarea_upd TYPE tt_ztarea.
    CLASS-DATA mt_buffer_tarea_del TYPE tt_ztarea.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_orden_trabajo RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zi_orden_trabajo RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE zi_orden_trabajo.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zi_orden_trabajo.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zi_orden_trabajo.

    METHODS read FOR READ
      IMPORTING keys FOR READ zi_orden_trabajo RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK zi_orden_trabajo.

    METHODS rba_Tareas FOR READ
      IMPORTING keys_rba FOR READ zi_orden_trabajo\_Tareas FULL result_requested RESULT result LINK association_links.

    METHODS cba_Tareas FOR MODIFY
      IMPORTING entities_cba FOR CREATE zi_orden_trabajo\_Tareas.

ENDCLASS.

CLASS lhc_ZI_ORDEN_TRABAJO IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.
    LOOP AT entities INTO DATA(entity).
      DATA ls_orden TYPE ztorden.
      ls_orden-fecha_inicio = entity-FechaInicio.
      ls_orden-fecha_fin = entity-FechaFin.
      ls_orden-orden_num = entity-OrdenNum.
      ls_orden-responsable = entity-Responsable.
      ls_orden-status = entity-Status.
      ls_orden-uuid = entity-Uuid.
      ls_orden-descripcion = entity-Descripcion.


      " Generación de UUID
      TRY.
          IF ls_orden-uuid IS INITIAL.
            ls_orden-uuid = cl_system_uuid=>create_uuid_x16_static( ).
          ENDIF.
        CATCH cx_uuid_error.
      ENDTRY.

      " Auditoría
      ls_orden-client = cl_abap_context_info=>get_user_alias( ).

      " Llenamos el BUFFER global
      APPEND ls_orden TO mt_buffer_insert.

      " Mapeo de respuesta para el UI
      APPEND VALUE #( %cid = entity-%cid
                      uuid = ls_orden-uuid ) TO mapped-zi_orden_trabajo.
    ENDLOOP.


  ENDMETHOD.

  METHOD update.

    LOOP AT entities INTO DATA(entity).
      " 1. Leemos el estado actual de la base de datos
      SELECT SINGLE * FROM ztorden WHERE uuid = @entity-Uuid INTO @DATA(ls_orden).

      " 2. Actualizamos solo los campos que el usuario cambió
      IF entity-%control-OrdenNum     = if_abap_behv=>mk-on.
        ls_orden-orden_num = entity-OrdenNum. ENDIF.
      IF entity-%control-Descripcion  = if_abap_behv=>mk-on.
        ls_orden-descripcion = entity-Descripcion. ENDIF.
      IF entity-%control-Status       = if_abap_behv=>mk-on.
        ls_orden-status = entity-Status. ENDIF.
      IF entity-%control-FechaInicio  = if_abap_behv=>mk-on.
        ls_orden-fecha_inicio = entity-FechaInicio. ENDIF.
      IF entity-%control-FechaFin     = if_abap_behv=>mk-on.
         ls_orden-fecha_fin = entity-FechaFin. ENDIF.
      IF entity-%control-Responsable  = if_abap_behv=>mk-on.
        ls_orden-responsable = entity-Responsable. ENDIF.

      APPEND ls_orden TO mt_buffer_update.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(key).
      APPEND VALUE #( uuid = key-Uuid ) TO mt_buffer_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    LOOP AT keys INTO DATA(key).

      SELECT SINGLE * FROM ztorden
        WHERE uuid = @key-uuid
        INTO @DATA(ls_orden).

      IF sy-subrc = 0.
        APPEND CORRESPONDING #( ls_orden ) TO result.
      ELSE.
        APPEND VALUE #( uuid = key-uuid ) TO failed-zi_orden_trabajo.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_Tareas.
  ENDMETHOD.

  METHOD cba_Tareas.
    LOOP AT entities_cba INTO DATA(entity_cba).
      LOOP AT entity_cba-%target INTO DATA(tarea_target).
        DATA ls_tarea TYPE zttarea.
        ls_tarea-uuid       = cl_system_uuid=>create_uuid_x16_static( ).
        ls_tarea-uuid_orden = entity_cba-Uuid. " Link con el padre
        ls_tarea-descripcion = tarea_target-Descripcion.
        ls_tarea-duracion_horas = tarea_target-DuracionHoras.
        ls_tarea-fecha_ejecucion = tarea_target-FechaEjecucion.
        ls_tarea-status = tarea_target-Status.
        ls_tarea-posicion = tarea_target-Posicion.
        ls_tarea-tecnico = tarea_target-Tecnico.


        APPEND ls_tarea TO mt_buffer_tarea_ins.

        APPEND VALUE #( %cid = tarea_target-%cid uuid = ls_tarea-uuid )
               TO mapped-zi_tarea.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_ZI_TAREA DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zi_tarea.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zi_tarea.

    METHODS read FOR READ
      IMPORTING keys FOR READ zi_tarea RESULT result.

    METHODS rba_Ordentrabajo FOR READ
      IMPORTING keys_rba FOR READ zi_tarea\_Ordentrabajo FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_ZI_TAREA IMPLEMENTATION.

  METHOD update.
     LOOP AT entities INTO DATA(entity).
      " 1. Recuperamos el registro actual de la tabla de tareas (zttarea)
      SELECT SINGLE * FROM zttarea WHERE uuid = @entity-Uuid INTO @DATA(ls_tarea).

      IF sy-subrc = 0.
        " 2. Mapeo selectivo según lo que cambió en la UI (%control)
        IF entity-%control-Descripcion    = if_abap_behv=>mk-on.
            ls_tarea-descripcion = entity-Descripcion. ENDIF.
        IF entity-%control-Status         = if_abap_behv=>mk-on.
            ls_tarea-status = entity-Status. ENDIF.
        IF entity-%control-DuracionHoras  = if_abap_behv=>mk-on.
            ls_tarea-duracion_horas = entity-DuracionHoras. ENDIF.
        IF entity-%control-Tecnico        = if_abap_behv=>mk-on.
            ls_tarea-tecnico = entity-Tecnico. ENDIF.
        IF entity-%control-FechaEjecucion = if_abap_behv=>mk-on.
            ls_tarea-fecha_ejecucion = entity-FechaEjecucion. ENDIF.

        " 3. Mandamos al buffer global que está en el Handler del Padre
        APPEND ls_tarea TO lhc_zi_orden_trabajo=>mt_buffer_tarea_upd.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
      LOOP AT keys INTO DATA(key).
      " Solo necesitamos la llave para borrar
      APPEND VALUE #( uuid = key-Uuid ) TO lhc_zi_orden_trabajo=>mt_buffer_tarea_del.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
        " Implementación básica para poder previsualizar datos
    LOOP AT keys INTO DATA(key).
      SELECT SINGLE * FROM zttarea WHERE uuid = @key-Uuid INTO @DATA(ls_tarea).
      IF sy-subrc = 0.
        APPEND CORRESPONDING #( ls_tarea ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_Ordentrabajo.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_ORDEN_TRABAJO DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_ORDEN_TRABAJO IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
       " --- PERSISTENCIA ORDEN (PADRE) ---
    IF lhc_zi_orden_trabajo=>mt_buffer_insert IS NOT INITIAL.
      INSERT ztorden FROM TABLE @lhc_zi_orden_trabajo=>mt_buffer_insert.
    ENDIF.
    IF lhc_zi_orden_trabajo=>mt_buffer_update IS NOT INITIAL.
      UPDATE ztorden FROM TABLE @lhc_zi_orden_trabajo=>mt_buffer_update.
    ENDIF.
    IF lhc_zi_orden_trabajo=>mt_buffer_delete IS NOT INITIAL.
      DELETE ztorden FROM TABLE @lhc_zi_orden_trabajo=>mt_buffer_delete.
    ENDIF.

    " --- PERSISTENCIA TAREAS (HIJO) ---
    " 1. Borrar tareas primero si es necesario
    IF lhc_zi_orden_trabajo=>mt_buffer_tarea_del IS NOT INITIAL.
      DELETE zttarea FROM TABLE @lhc_zi_orden_trabajo=>mt_buffer_tarea_del.
    ENDIF.

    " 2. Insertar nuevas tareas (creadas via Asociación)
    IF lhc_zi_orden_trabajo=>mt_buffer_tarea_ins IS NOT INITIAL.
      INSERT zttarea FROM TABLE @lhc_zi_orden_trabajo=>mt_buffer_tarea_ins.
    ENDIF.

    " 3. Actualizar tareas existentes
    IF lhc_zi_orden_trabajo=>mt_buffer_tarea_upd IS NOT INITIAL.
      UPDATE zttarea FROM TABLE @lhc_zi_orden_trabajo=>mt_buffer_tarea_upd.
    ENDIF.

    " --- LIMPIEZA TOTAL DE BUFFERS ---
    CLEAR: lhc_zi_orden_trabajo=>mt_buffer_insert,
           lhc_zi_orden_trabajo=>mt_buffer_update,
           lhc_zi_orden_trabajo=>mt_buffer_delete,
           lhc_zi_orden_trabajo=>mt_buffer_tarea_ins,
           lhc_zi_orden_trabajo=>mt_buffer_tarea_upd,
           lhc_zi_orden_trabajo=>mt_buffer_tarea_del.

  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
