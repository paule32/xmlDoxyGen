unit MainWindow;

interface

type
    /**
     * @brief This is class QMainWindow.
     * @details ein Fenster
     * @since version 5
     */
    QMainWindow = class(QObject)
    private
        FId: Integer;
        FName: String;
    public
        constructor Create;
        destructor Destroy; override;
        
        /// Gibt eine ID zurück
        property Id: Integer read FId;
    end;

implementation

end.
